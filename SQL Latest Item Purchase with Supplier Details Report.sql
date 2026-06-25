/*
===============================================================================
SQL Latest Item Purchase with Supplier Details Report
Author: Hanan Altarjami

Purpose:
    This SQL query retrieves the latest purchase order details per item,
    including supplier information, buyer details, pricing, and received quantities.

    It returns the most recent PO line per item based on creation date.

Tables Used:
    - PO_HEADERS_ALL              (Purchase Order Header)
    - PO_LINES_ALL                (Purchase Order Lines)
    - EGP_SYSTEM_ITEMS_VL         (Item Master Information)
    - PER_PERSON_NAMES_F_V       (Buyer Information)
    - POZ_SUPPLIERS_V            (Supplier Information)
    - RCV_SHIPMENT_LINES         (Receipt Transactions)

Report Output:
    - PO Number
    - PO Creation Date
    - Buyer Name
    - Supplier Name
    - Item Number
    - Line Number
    - Unit Price
    - Ordered Quantity
    - UOM
    - Line Value
    - Total Quantity Received

Parameters:
    :p_item_number   - Filter by Item Number (optional)

Notes:
    - Uses analytic functions to identify latest PO per item.
    - Calculates total received quantity per PO line.
    - Suitable for reporting and supplier analysis.

Module:
    Oracle Fusion SCM – Procurement

===============================================================================
*/

SELECT
    po_number,              -- Purchase Order Number
    po_creation_date,       -- PO Creation Date (formatted)
    buyer_name,             -- Buyer responsible for the PO
    vendor_name,           -- Supplier Name
    item_number,           -- Inventory Item Number
    line_num,              -- PO Line Number
    unit_price,            -- Unit Price per item
    ordered_qty,           -- Ordered Quantity
    po_line_uom,           -- Unit of Measure
    linevalue,             -- Total Line Value (Unit Price * Quantity)
    total_qty_received     -- Total received quantity per PO line
FROM (
    SELECT
        pha.segment1 AS po_number,   -- PO Number from header

        TO_CHAR(pha.creation_date, 'YYYY-MM-DD HH24:MI')
            AS po_creation_date,     -- Formatted creation date

        pn.full_name AS buyer_name,  -- Buyer full name
        ps.vendor_name,              -- Supplier name
        esi.item_number,             -- Item number from item master

        pla.line_num,                -- PO line number
        pla.unit_price,              -- Unit price
        pla.quantity AS ordered_qty, -- Ordered quantity
        pla.uom_code AS po_line_uom, -- UOM code
        pla.unit_price * pla.quantity AS linevalue, -- Line total value

        SUM(NVL(rsl.quantity_received,0))
            OVER (PARTITION BY pla.po_line_id) AS total_qty_received,
            -- Total received quantity per PO line

        ROW_NUMBER() OVER (
            PARTITION BY esi.item_number
            ORDER BY pha.creation_date DESC
        ) AS rn
        -- Used to keep only the latest PO per item

    FROM po_headers_all pha
    JOIN po_lines_all pla
      ON pla.po_header_id = pha.po_header_id

    JOIN egp_system_items_vl esi
      ON esi.inventory_item_id = pla.item_id

    JOIN per_person_names_f_v pn
      ON pn.person_id = pha.agent_id

    JOIN poz_suppliers_v ps
      ON ps.vendor_id = pha.vendor_id

    LEFT JOIN rcv_shipment_lines rsl
      ON rsl.po_header_id = pha.po_header_id
     AND rsl.po_line_id   = pla.po_line_id

    /* Item filter parameter (optional) */
    WHERE (esi.item_number = :p_item_number
           OR :p_item_number IS NULL)
)

WHERE rn = 1   -- Keep only latest PO per item
ORDER BY po_creation_date DESC






