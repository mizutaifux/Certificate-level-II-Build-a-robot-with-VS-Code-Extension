*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Desktop
Library    RPA.Tables
Library    RPA.Robocorp.WorkItems
Library    RPA.RobotLogListener
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    Process
Library    RPA.Robocloud.Secrets

*** Variables ***
${TEMPDIR}     ${OUTPUT_DIR}${/}temp
#--LOCAL--${RESULTDIR}   ${OUTPUT_DIR}${/}output
${RESULTDIR}   ${OUTPUT_DIR}
${INPUTDIR}    ${OUTPUT_DIR}${/}input
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       1.5s

*** Tasks ***    
Order robots from RobotSpareBin Industries Inc    
    Download CSV Orders File
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        # Sometimes the submit fails. 
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Submit the order        
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Create a ZIP file of the receipts        
    [Teardown]    Close Browser
        
*** Keywords ***
Download CSV Orders File
    # 20: Configure and run the robot as an assistant that asks for user input    
    #Add heading    Enter URL CSV Order File
    #Add text input  urlcsvorder    label=URL    placeholder=https://robotsparebinindustries.com/orders.csv
    #${fullurl}=    Run dialog
    #Download    ${fullurl}[urlcsvorder]    target_file=${INPUTDIR}${/}orders.csv    overwrite=true
    # Control Room !
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${INPUTDIR}${/}orders.csv    overwrite=true

Open the robot order website
    ${secret}=    Get Secret    parameters    
    Open Available Browser    ${secret}[urlorder]

Get orders    
    ${orders}=    Read table from CSV    ${INPUTDIR}${/}orders.csv      dialect=excel    header=true
    Return From Keyword     ${orders}

Close the annoying modal
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form    
    [Arguments]        ${row}       
    Select From List By Value    head   ${row}[Head]
    Select Radio Button    body    ${row}[Body]                      
    ${inputdynamicid}=    Get Element Attribute    xpath://input[@type='number']    id    
    Input Text    identifier:${inputdynamicid}      ${row}[Legs]    
    Input Text    address    ${row}[Address]


Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    id:receipt

Create a ZIP file of the receipts
    Archive Folder With Zip    ${TEMPDIR}    ${RESULTDIR}${/}OrdersDetail.zip


Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${htmldata}=           Get Element Attribute    receipt    outerHTML
    Html To Pdf                   ${htmldata}                       ${TEMPDIR}${/}${Order number}.pdf
    Return From Keyword    ${TEMPDIR}${/}${Order number}.pdf
    
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot                    robot-preview-image           ${INPUTDIR}${/}${Order number}.png    
    Return From Keyword     ${INPUTDIR}${/}${Order number}.png  

Embed the robot screenshot to the receipt PDF file 
    [Arguments]    ${html}     ${screenshot}    
    Open Pdf                      ${html}
    Add Watermark Image To Pdf    ${screenshot}      ${html}
    Close Pdf                     ${html}

Go to order another robot    
    ${secret}=    Get Secret    parameters    
    Go To    ${secret}[urlorder]
