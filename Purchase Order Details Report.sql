/*
===============================================================================
Purchase Order Details Report
Author: Hanan Altarjami

Purpose:
    Retrieve purchase order header and line details including supplier,
    item information, pricing, and PO status for standard purchase orders.

Tables Used:
    - PO_HEADERS_ALL        (PO Header Information)
    - PO_LINES_ALL          (PO Line Information)
    - POZ_SUPPLIERS         (Supplier Master)
    - HZ_PARTIES            (Supplier Party Details)
    - EGP_SYSTEM_ITEMS_B    (Item Master)
    - PO_LINE_TYPES_B       (PO Line Types)

Report Output:
    - PO Number
    - Document Status
    - Creation Date
    - Supplier Name
    - Line Number
    - Item Description
    - Item Number
    - Quantity
    - Unit Price
    - UOM Code
    - Purchase Basis
    - Line Type Code

Parameters:
    - p_from_date
    - p_to_date
    - po_number

Notes:
    - Filters only STANDARD purchase orders.
    - Supports optional filtering by PO number and creation date range.
    - Uses NVL for flexible parameter handling.
    - Left join used for item master to include non-item lines.

Module:
    Oracle Fusion SCM – Procurement
===============================================================================
*/

SELECT DISTINCT

       -- PO Number
       POH.SEGMENT1 AS PO_NUMBER,

       -- Document Status
       POH.DOCUMENT_STATUS,

       -- Creation Date
       TO_CHAR(POH.CREATION_DATE, 'DD-MM-YYYY') AS CREATION_DATE,

       -- Supplier Name
       HP.PARTY_NAME AS SUPPLIER_NAME,

       -- Line Number
       POL.LINE_NUM,

       -- Item Description
       POL.ITEM_DESCRIPTION,

       -- Item Number
       EGP.ITEM_NUMBER,

       -- Quantity
       POL.QUANTITY,

       -- Unit Price
       POL.UNIT_PRICE,

       -- UOM Code
       POL.UOM_CODE,

       -- Purchase Basis
       POL.PURCHASE_BASIS,

       -- Line Type Code
       POT.LINE_TYPE_CODE

FROM
       PO_HEADERS_ALL POH,
       POZ_SUPPLIERS POS,
       HZ_PARTIES HP,
       PO_LINES_ALL POL,
       EGP_SYSTEM_ITEMS_B EGP,
       PO_LINE_TYPES_B POT

WHERE 1 = 1

      -- Supplier Join
  AND POH.VENDOR_ID = POS.VENDOR_ID

      -- Supplier Party Join
  AND POS.PARTY_ID = HP.PARTY_ID

      -- Line Type Join
  AND POL.LINE_TYPE_ID = POT.LINE_TYPE_ID

      -- PO Header to Lines
  AND POH.PO_HEADER_ID = POL.PO_HEADER_ID

      -- Item Join (Outer Join)
  AND POL.ITEM_ID = EGP.INVENTORY_ITEM_ID (+)

      -- PO Number Parameter
  AND POH.SEGMENT1 = NVL(:po_number, POH.SEGMENT1)

      -- Date Range Filter
  AND TRUNC(POH.CREATION_DATE)
          BETWEEN NVL(:p_from_date, TRUNC(POH.CREATION_DATE))
              AND NVL(:p_to_date, TRUNC(POH.CREATION_DATE))

      -- Standard Purchase Orders Only
  AND POH.TYPE_LOOKUP_CODE = 'STANDARD'

ORDER BY
       POH.SEGMENT1 ASC