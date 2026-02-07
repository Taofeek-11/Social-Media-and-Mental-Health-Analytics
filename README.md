# Social Media Exposure and Mental Health Analytics

## Overview

This project presents a descriptive analytics study of social media exposure patterns and associated mental health indicators using survey-based data. The analysis focuses on how varying levels of daily social media use align with mean scores across multiple mental health constructs, with results explored interactively through SQL-driven preprocessing and Tableau dashboards.

The project is designed as an applied analytics workflow, emphasizing transparent data preparation, reproducible analysis, and clear visual communication rather than causal inference.

---

## Research Objective

To examine patterns of social media exposure and describe how mental health indicators vary across levels of daily social media use, with subgroup analysis by age group and relationship status.

---

## Dataset Description

* Source: Survey data collected for an academic statistics project https://www.kaggle.com/datasets/adilshamim8/social-media-addiction-vs-relationships 
* Unit of analysis: Individual respondents
* Key variables:

  * Demographics: age, gender, relationship status
  * Social media exposure: time spent per day, platforms used
  * Mental health indicators: attention difficulties, anxiety symptoms, depressive symptoms, self-esteem vulnerability (composite indices)
* Data characteristics:

  * Cross-sectional
  * Self-reported
  * Aggregated and anonymized for analysis

---

## Methods

* Data cleaning and transformation performed in MySQL
* Construction of composite mental health indices using averaged survey items
* Descriptive analysis of:

  * Exposure distributions
  * Platform usage patterns
  * Mean mental health scores across exposure levels
* Dynamic subgroup analysis by age group and relationship status
* Visualization and narrative presentation implemented in Tableau

All findings are interpreted descriptively. No causal or predictive claims are made.

---

## Tools and Technologies

* SQL (MySQL 8+) for data preparation and analysis
* Tableau for interactive dashboards and story-based reporting
* Git and GitHub for version control and documentation

---

## Repository Structure

```
social-media-exposure-mental-health-analytics/
│
├── sql/
│   ├── 01_schema_load.sql
│   ├── 02_data_cleaning.sql
│   └── 03_analysis_queries.sql
│
├── tableau/
│   ├── dashboard.twbx
│   └── exports/
│
├── docs/
│   ├── methodology.md
│   └── data_dictionary.md
│
├── data/
│   └── raw
│   └── processed
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## Key Findings (Summary)

* Younger respondents constitute the largest share of the sample and report higher overall social media exposure.
* A substantial proportion of respondents report moderate to high daily social media use (three hours or more).
* Mean scores for attention difficulties, anxiety symptoms, depressive symptoms, and self-esteem vulnerability increase systematically across higher exposure categories.
* These exposure–mental health patterns persist across age and relationship status subgroups, although absolute mean levels vary demographically.

---

## Reproducibility

To reproduce the analysis:

1. Load a compatible survey dataset into MySQL.
2. Execute SQL scripts in numerical order.
3. Connect Tableau to the resulting tables or views.
4. Apply demographic filters within the dashboard to explore subgroup patterns.

---

## Limitations

* Cross-sectional design
* Self-reported measures
* Descriptive analysis only; no causal inference

These constraints are acknowledged and reflected in the interpretation of results.

---

## License and Use

This project is provided for academic, educational, and portfolio purposes. If reused or adapted, appropriate attribution is required.

---
* tailor this README for **portfolio vs academic submission**,
* compress it further for a **minimal GitHub README**, or
* write a **methodology.md** that aligns with journal/thesis standards.
