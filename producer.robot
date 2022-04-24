*** Settings ***
Documentation     Inhuman Insurance, Inc. Artificial Intelligence System robot.
...               Produces traffic data work items.
Library           Collections
Library           RPA.Tables
Resource          shared.robot

*** Variables ***
${TRAFFIC_DATA_URL}=    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
${TRAFFIC_JSON_FILE}=    ${OUTPUT_DIR}${/}traffic.json
# JSON data keys:
${COUNTRY_KEY}=    SpatialDim
${GENDER_KEY}=    Dim1
${RATE_KEY}=      NumericValue
${YEAR_KEY}=      TimeDim

*** Tasks ***
Produce traffic data work items
    Download traffic data
    ${traffic_data}=    Load traffic data as table
    # Write table to CSV    table=${traffic_data}    path=test.csv
    ${filtered_data}=    Filter and sort traffic data    ${traffic_data}
    ${filtered_data}=    Get latest data by country    ${filtered_data}
    ${payloads}=    Create work item payloads    ${filtered_data}
    Save work item payloads    ${payloads}

*** Keywords ***
Download traffic data
    Download
    ...    url=${TRAFFIC_DATA_URL}
    ...    target_file=${TRAFFIC_JSON_FILE}
    ...    overwrite=True

Load traffic data as table
    ${json}=    Load JSON from file    filename=${TRAFFIC_JSON_FILE}
    ${table}=    Create Table    ${json}[value]
    [Return]    ${table}

Filter and sort traffic data
    [Arguments]    ${table}
    ${max_rate}=    Set Variable    ${5.0}
    ${both_genders}=    Set Variable    BTSX
    Filter Table By Column    table=${table}    column=${RATE_KEY}    operator=<    value=${max_rate}
    Filter Table By Column    table=${table}    column=${GENDER_KEY}    operator= ==    value=${both_genders}
    Sort Table By Column    table=${table}    column=${YEAR_KEY}    ascending=False
    [Return]    ${table}

Get latest data by country
    [Arguments]    ${table}
    ${table}=    Group Table By Column    table=${table}    column=${COUNTRY_KEY}
    ${latest_data_by_country}=    Create List
    FOR    ${group}    IN    @{table}
        ${first_row}=    Pop Table Row    table=${group}
        Append To List    ${latest_data_by_country}    ${first_row}
    END
    [Return]    ${latest_data_by_country}

Create work item payloads
    [Arguments]    ${traffic_data}
    ${payloads}=    Create List
    FOR    ${row}    IN    @{traffic_data}
        ${payload}=
        ...    Create Dictionary
        ...    country=${row}[${COUNTRY_KEY}]
        ...    year=${row}[${YEAR_KEY}]
        ...    rate=${row}[${RATE_KEY}]
        Append To List    ${payloads}    ${payload}
    END
    [Return]    ${payloads}

Save work item payloads
    [Arguments]    ${payloads}
    FOR    ${payload}    IN    @{payloads}
        Save work item payload    ${payload}
    END

Save work item payload
    [Arguments]    ${payload}
    ${variables}=    Create Dictionary    ${WORK_ITEM_NAME}=${payload}
    Create Output Work Item    variables=${variables}    save=True
