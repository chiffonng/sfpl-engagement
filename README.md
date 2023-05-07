# Summary
Access and clean patron records (437K rows) from San Francisco Public Library (SFPL) from [DataSF](https://data.sfgov.org/Culture-and-Recreation/Library-Usage/qzz6-2jup). The public dataset represents the library usage of inventoried items by active patrons, last updated Feb 2023.

The ultimate goal is to be able to run the SQL script with the updated dataset with only minimial pre-processing. See steps below.

Credits: Syntax and naming conventions referred from [Alexander Wong](https://github.com/AlexanderWong/Library-Management-System/blob/master/LibraryManagementSystemAndStoredProceduresFINAL.sql)

# Processing
## Pre-requisites
1. Download the Excel file from [DataSF](https://data.sfgov.org/Culture-and-Recreation/Library-Usage/qzz6-2jup).
2. Rename all 14 column headers such that they match those in [SQL script](https://github.com/chiffonng/sfpl-management/blob/master/sfpl_usage.sql). This can be done on Excel or Google Sheets
    - patron_type_code
    - patron_type
    - checkouts_total
    - renewals_total
    - age_range
    - registration_year
    - library_code
    - library_branch
    - circulation_active_month
    - circulation_active_year
    - notification_medium_code
    - notification_medium
    - email_notification
    - isin_sf
3. Change the file type from Excel `.xlsx` to CSV `sfpl_usage.csv`
4. Move the CSV file and SQL script in the same folder. Otherwise, configure the path to include the actual path to the CSV file ([line 23]((https://github.com/chiffonng/sfpl-management/blob/master/sfpl_usage.sql)).
## SQL script
Major changes applied to the dataset include
- Removing all records/rows where there is no information about circulation activity for patrons.
- Creating a new column `last_active` that represents the last time patrons 

By default, end users will see the cleaned data and 3 views
- Patron type VS age range
- Summary statistics by patron types (distribution of patrons, average # checkouts, average # renewals.
- Summary statistics by library branch

More views can be created and stored through `CREATE VIEW`. Similarly, queries can be created and stored through `CREATE PROC`
