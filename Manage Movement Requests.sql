/* 
===============================================================================
SQL Material Request (MR) Report
Author: Hanan Altarjami

Purpose:
    This SQL query retrieves Material Request (MR) details including request
    number, creation date, organization, transaction type, request status,
    employee information, item details, requested quantity, and delivered quantity.

Tables Used:
    - INV_TXN_REQUEST_HEADERS      (Material Request Header)
    - INV_TXN_REQUEST_LINES        (Material Request Lines)
    - INV_ORG_PARAMETERS           (Inventory Organization Details)
    - INV_TRANSACTION_TYPES_B      (Transaction Type Base Table)
    - INV_TRANSACTION_TYPES_TL     (Transaction Type Translation Table)
    - EGP_SYSTEM_ITEMS_VL          (Item Master Information)

Report Output:
    - Material Request Number
    - Creation Date
    - Organization Code
    - Transaction Type
    - Header Status
    - Employee Name
    - Department
    - Vehicle Information
    - Line Number
    - Line Status
    - Item Number & Description
    - UOM
    - Requested Quantity
    - Delivered Quantity

Parameters:
    :MR_Number       - Material Request Number
    :Employee_Name   - Employee Name
    :p_from_date     - From Creation Date
    :p_to_date       - To Creation Date

Notes:
    - Supports filtering by MR Number, Employee Name, and Date Range.
    - Intended for reporting and analysis purposes.
    - Output can be exported to PDF or Excel formats.

Module:
    Oracle Fusion SCM – Inventory Management

===============================================================================
*/


SELECT DISTINCT

    MRH.HEADER_ID,                                              -- Material Request Header ID
    MRH.REQUEST_NUMBER,                                         -- Material Request Number
    TO_CHAR(MRH.CREATION_DATE,'DD-MM-YYYY') AS CREATION_DATE,    -- Creation Date (Formatted)
    MRH.DESCRIPTION,                                            -- Request Description

    IVP.ORGANIZATION_CODE,                                      -- Inventory Organization Code

    TL.TRANSACTION_TYPE_NAME,                                   -- Transaction Type Name

    DECODE(MRH.HEADER_STATUS,                                   -- Header Status Description
        1, 'Incomplete',
        2, 'Pending Approval',
        3, 'Approved',
        4, 'Rejected',
        5, 'Closed',
        6, 'Canceled',
        7, 'Preapproved',
        8, 'Canceled by Source',
        'Unknown') AS HEADER_STATUS,

    MRH.ATTRIBUTE1 AS EMPLOYEE,                                 -- Employee Name
    MRH.ATTRIBUTE2 AS DEPARTMENT,                               -- Department
    MRH.ATTRIBUTE3 AS VEHICLE,                                  -- Vehicle Info

    MRL.LINE_NUMBER,                                            -- Line Number

    DECODE(MRL.LINE_STATUS,                                     -- Line Status Description
        1, 'Incomplete',
        2, 'Pending Approval',
        3, 'Approved',
        4, 'Rejected',
        5, 'Closed',
        6, 'Canceled',
        7, 'Preapproved',
        9, 'Canceled by Source',
        'Unknown') AS LINE_STATUS,

    ITS.ITEM_NUMBER,                                            -- Item Number
    ITS.DESCRIPTION AS ITEM_DESCRIPTION,                        -- Item Description

    MRL.UOM_CODE,                                               -- Unit of Measure
    MRL.QUANTITY,                                               -- Requested Quantity
    MRL.QUANTITY_DELIVERED                                      -- Delivered Quantity

FROM

    INV_TXN_REQUEST_HEADERS MRH,                                -- MR Header Table
    INV_ORG_PARAMETERS IVP,                                     -- Inventory Organization Table
    INV_TRANSACTION_TYPES_B TRB,                                -- Transaction Type Base
    INV_TRANSACTION_TYPES_TL TL,                                -- Transaction Type Translation
    INV_TXN_REQUEST_LINES MRL,                                  -- MR Lines Table
    EGP_SYSTEM_ITEMS_VL ITS                                     -- Item Master Table

WHERE 1 = 1                                                     -- Base condition for dynamic filtering

    AND MRH.HEADER_ID = MRL.HEADER_ID                           -- Join Header to Lines
    AND MRH.ORGANIZATION_ID = IVP.ORGANIZATION_ID               -- Join Organization
    AND MRH.TRANSACTION_TYPE_ID = TRB.TRANSACTION_TYPE_ID       -- Join Transaction Type (Base)
    AND TL.TRANSACTION_TYPE_ID = TRB.TRANSACTION_TYPE_ID        -- Join Transaction Type (Translation)
    AND ITS.INVENTORY_ITEM_ID = MRL.INVENTORY_ITEM_ID           -- Join Item Master
    AND TL.LANGUAGE = 'US'                                      -- English Language Filter

    -- Parameter Filters
    AND MRH.REQUEST_NUMBER = NVL(:MR_Number, MRH.REQUEST_NUMBER)
    AND MRH.ATTRIBUTE1 = NVL(:Employee_Name, MRH.ATTRIBUTE1)

    -- Date Range Filter
    AND TRUNC(MRH.CREATION_DATE)
        BETWEEN NVL(:p_from_date, TRUNC(MRH.CREATION_DATE))
            AND NVL(:p_to_date, TRUNC(MRH.CREATION_DATE))

ORDER BY

    MRH.REQUEST_NUMBER ASC,                                     -- Sort by Request Number
    MRL.LINE_NUMBER ASC                                       -- Sort by Line Number