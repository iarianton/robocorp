*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocorp.Vault


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser    ${secret}[url]

*** Keywords ***
Collect file from user
    Add heading    Upload File
    Add file input
    ...    label=Upload the file with orders data
    ...    name=fileupload
    ...    file_type=CSV files (*.csv)
    ...    destination=${CURDIR}${/}output
    ${response}=    Run dialog
    [Return]    ${response.fileupload}[0]

*** Keywords ***
Close the annoying modal
    Click Button    css:.btn-dark

*** Keywords ***
Preview the robot
    Click Button    id:preview
    FOR    ${i}    IN RANGE    3
        ${preview_ok}=    Does Page Contain Element    id:robot-preview
        IF    ${preview_ok} == False
        Click Button    id:preview
        ELSE
        Log    ${preview_ok}
        Exit For Loop If    ${preview_ok}
        END
    END

*** Keywords ***
Submit the order
    Click Button    id:order
    FOR    ${i}    IN RANGE    3
        ${submit_ok}=    Does Page Contain    Receipt
        IF    ${submit_ok} == False
        Click Button    id:order
        ELSE
        Log    ${submit_ok}
        Exit For Loop If    ${submit_ok}
        END
    END

*** Keywords ***
Complete order
    [Arguments]    ${row}
    Close the annoying modal
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:.form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Preview the robot
    Submit the order

*** Keywords ***
Export as a PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${receipt}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}orders${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}orders${/}${order_number}.pdf

*** Keywords ***
Screenshot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}orders${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}orders${/}${order_number}.png

*** Keywords ***
Add image to PDF
    [Arguments]    ${order_number}
    Add Watermark Image To PDF
    ...    image_path=${CURDIR}${/}output${/}orders${/}${order_number}.png
    ...    source_path=${CURDIR}${/}output${/}orders${/}${order_number}.pdf
    ...    output_path=${CURDIR}${/}output${/}orders${/}receipts${/}order-${order_number}.pdf

*** Keywords ***
Make another order
    Wait Until Element Is Visible   id:order-another
    Click Button    id:order-another

*** Keywords ***
Close browser
    Close Window

*** Keywords ***
Complete all orders
    ${table}=   Read table from CSV   orders.csv
    FOR    ${row}    IN    @{table}
        Complete order    ${row}
        ${receipt}=    Export as a PDF    ${row}[Order number]
        ${screenshot}=    Screenshot    ${row}[Order number]
        ${pdf}=    Add image to PDF    ${row}[Order number]
        Make another order
    END
    Close browser

*** Keywords ***
ZIP folder
    Archive Folder With Zip  ${CURDIR}${/}output${/}orders${/}receipts    output${/}receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Collect file from user
    Complete all orders
    ZIP folder
