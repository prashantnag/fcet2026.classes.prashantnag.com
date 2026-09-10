suppressPackageStartupMessages(library(lubridate))
library(glue)
library(calendar)
library(readr)
library(dplyr)
library(purrr)
library(tidyr)

read_schedule_csv <- function(path) {
  normalise_date <- function(x) {
    # Accept DD-MM-YYYY or YYYY-MM-DD; return YYYY-MM-DD string (or NA)
    dplyr::case_when(
      grepl("^\\d{2}-\\d{2}-\\d{4}$", x) ~ format(as.Date(x, format = "%d-%m-%Y"), "%Y-%m-%d"),
      grepl("^\\d{4}-\\d{2}-\\d{2}$", x) ~ x,
      TRUE ~ NA_character_
    )
  }
  df <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA")) |>
    tibble::as_tibble()
  df$date     <- normalise_date(df$date)
  df$end_date <- normalise_date(df$end_date)
  df
}

save_ical <- function(df, path) {
  calendar::ic_write(df, path)
  path
}

icon_link <- function(path, icon_class, anchor = "", placeholder = FALSE) {
  if (is.na(path) || path == "") {
    if (placeholder) {
      return(glue('<span style="color:#e9ecef"><i class="{icon_class} fa-lg"></i></span>'))
    }
    return("")
  }

  href <- if (anchor == "") glue("{path}.qmd") else glue("{path}.qmd#{anchor}")
  glue('<a href="{href}"><i class="{icon_class} fa-lg"></i></a>')
}

build_schedule_for_page <- function(schedule_file) {
  schedule <- read_schedule_csv(schedule_file) |>
    mutate(
      date = as.Date(date),
      end_date = as.Date(end_date),
      deadline_time = suppressWarnings(hms(deadline)),
      date_range = case_when(
        !is.na(date) & !is.na(end_date) ~ glue('{format(date, "%B %e")}–{format(end_date, "%B %e")}'),
        !is.na(date) ~ format(date, "%B %e"),
        TRUE ~ ""
      ),
      deadline_actual = if_else(
        is.na(deadline_time) | is.na(date),
        as.POSIXct(NA),
        update(
          as.POSIXct(date),
          hour = hour(deadline_time),
          minute = minute(deadline_time),
          second = second(deadline_time)
        )
      ),
      deadline_nice = if_else(is.na(deadline_actual), "", format(deadline_actual, "%I:%M %p"))
    ) |>
    mutate(
      group = if_else(is.na(group), "Schedule", group),
      session = if_else(is.na(session), "", session),
      title = if_else(is.na(title), "", title),
      lecture = if_else(is.na(lecture), "", lecture),
      quiz = if_else(is.na(quiz), "", quiz),
      content = if_else(is.na(content), "", content),
      lab = if_else(is.na(lab), "", lab),
      assignment = if_else(is.na(assignment), "", assignment),
      note = if_else(is.na(note), "", note)
    ) |>
    mutate(
      # Derive content anchor from session: "Lecture 7" → "lecture-7", others → ""
      content_anchor = case_when(
        grepl("^Lecture \\d+$", session) ~ tolower(gsub(" ", "-", session)),
        TRUE ~ ""
      )
    )

  schedule <- schedule |>
    mutate(
      group_order = case_when(
        grepl("^Week \\d+$", group) ~ as.integer(sub("^Week ", "", group)),
        group == "Assessment" ~ 999L,
        TRUE ~ 1000L
      )
    ) |>
    arrange(group_order, date, end_date, session)

  group_levels <- schedule |>
    distinct(group, group_order) |>
    arrange(group_order, group) |>
    pull(group)

  schedule |>
    mutate(
      group = factor(group, levels = group_levels),
      col_date = if_else(date_range == "", "", glue('<span class="content-date">{date_range}</span>')),
      col_title = case_when(
        session != "" & deadline_nice != "" ~ glue('<em>{session}</em> {title}<br><small class="text-muted">Due by {deadline_nice}</small>'),
        session != "" ~ glue('<em>{session}</em> {title}'),
        deadline_nice != "" ~ glue('{title}<br><small class="text-muted">Due by {deadline_nice}</small>'),
        TRUE ~ title
      ),
      col_title = if_else(note == "", col_title, glue('{col_title}<br><small>{note}</small>')),
      col_quiz = map_chr(quiz, ~icon_link(.x, "fa-solid fa-list-check")),
      col_lecture = map_chr(lecture, ~icon_link(.x, "fa-solid fa-desktop")),
      col_content = map2_chr(content, content_anchor, ~icon_link(.x, "fa-solid fa-book-open-reader", anchor = .y)),
      col_lab = map_chr(lab, ~icon_link(.x, "fa-solid fa-flask")),
      col_assignment = map_chr(assignment, ~icon_link(.x, "fa-solid fa-pen-ruler"))
    ) |>
    select(
      group,
      ` ` = col_date,
      Topic = col_title,
      Quiz = col_quiz,
      Lecture = col_lecture,
      Content = col_content,
      Lab = col_lab,
      Assignment = col_assignment
    ) |>
    group_by(group) |>
    nest() |>
    mutate(group = as.character(group))
}

build_ical <- function(schedule_file, base_url, page_suffix, course_number) {
  dtstamp <- ic_char_datetime(now("UTC"), zulu = TRUE)

  schedule <- read_schedule_csv(schedule_file) |>
    mutate(
      date = as.Date(date),
      end_date = as.Date(end_date),
      session = if_else(is.na(session), "", session),
      title = if_else(is.na(title), "", title),
      lecture = if_else(is.na(lecture), "", lecture),
      quiz = if_else(is.na(quiz), "", quiz),
      content = if_else(is.na(content), "", content),
      lab = if_else(is.na(lab), "", lab),
      assignment = if_else(is.na(assignment), "", assignment),
      summary = trimws(glue("{course_number}: {session} {title}")),
      event_end = coalesce(end_date, date),
      url = coalesce(
        na_if(assignment, ""),
        na_if(lab, ""),
        na_if(quiz, ""),
        na_if(lecture, ""),
        na_if(content, "")
      ),
      url = if_else(is.na(url), "", glue("{base_url}{url}{page_suffix}"))
    ) |>
    filter(!is.na(date))

  schedule |>
    mutate(id = row_number()) |>
    group_by(id) |>
    nest() |>
    mutate(
      ical = map(data, ~ic_event(
        start = as.POSIXct(.x$date[[1]], format = "%Y-%m-%d"),
        end = as.POSIXct(.x$event_end[[1]], format = "%Y-%m-%d") + 24 * 60 * 60,
        summary = .x$summary[[1]],
        more_properties = TRUE,
        event_properties = c(
          "DESCRIPTION" = .x$url[[1]],
          "DTSTAMP" = dtstamp
        )
      ))
    ) |>
    ungroup() |>
    select(-id, -data) |>
    unnest(ical) |>
    ical() |>
    rename(
      `DTSTART;VALUE=DATE` = DTSTART,
      `DTEND;VALUE=DATE` = DTEND
    )
}
