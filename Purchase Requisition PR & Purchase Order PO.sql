/* 
===============================================================================
SQL PR and PO with PR requester Report
Author: Hanan Altarjami

Purpose: 

    This SQL query retrieves Purchase Requisition (PR) and Purchase Order (PO)
    details including requisition number, document status, preparer name, 
    item details, supplier information, and related PO number.

Tables Used:

    - POR_REQUISITION_HEADERS_ALL (PR Header)
    - POR_REQUISITION_LINES_ALL (PR Lines)
    - PER_PERSON_NAMES_F (Employee Information)
    - PER_ALL_ASSIGNMENTS_M (Assignment Details)
    - PO_HEADERS_ALL (PO Header)
    - EGP_SYSTEM_ITEMS_B (Item Master)
    - POZ_SUPPLIERS, HZ_PARTIES (Supplier Info)

Notes:

    - Filter Date Range
    - Export format for Report as PDF, Excel

Modules: Supply Chain Management (SCM)

===============================================================================
*/

WITH rcv AS (
    SELECT
        rsh.po_line_location_id,
        LISTAGG(DISTINCT rshh.receipt_num, ', ')
            WITHIN GROUP (ORDER BY rshh.receipt_num) AS receipt_nums,
        SUM(NVL(rsh.quantity_shipped,   0)) AS quantity_shipped,
        SUM(NVL(rsh.quantity_received,  0)) AS quantity_received,
        SUM(NVL(rsh.quantity_delivered, 0)) AS quantity_delivered,
        SUM(NVL(rsh.quantity_returned,  0)) AS quantity_returned
    FROM rcv_shipment_lines rsh
    JOIN rcv_shipment_headers rshh
      ON rshh.shipment_header_id = rsh.shipment_header_id
    GROUP BY rsh.po_line_location_id
)

SELECT
    etem.item_number,
    prh.requisition_number,
    TO_CHAR(prh.creation_date, 'YYYY-MM-DD') AS pr_creation_date,
    prh.document_status AS pr_status,
    per.display_name AS preparer_name,
    prl.item_description,
    prl.uom_code,
    prl.quantity AS pr_quantity,

    poh.segment1 AS po_number,
    pol.quantity AS po_quantity,

    rcv.quantity_received,

    NVL(pol.quantity, 0) - NVL(rcv.quantity_received, 0)
        AS remaining_quantity,

    TO_CHAR(poh.approved_date, 'YYYY-MM-DD') AS po_approved_date,
    poh.document_status AS po_status,
    hp.party_name AS supplier_name,

    rcv.receipt_nums,
    rcv.quantity_shipped,
    rcv.quantity_delivered,
    rcv.quantity_returned

FROM por_requisition_headers_all prh
JOIN por_requisition_lines_all prl
  ON prl.requisition_header_id = prh.requisition_header_id

JOIN per_person_names_f per
  ON per.person_id = prh.preparer_id
 AND per.name_type = 'GLOBAL'
 AND TRUNC(SYSDATE) BETWEEN per.effective_start_date AND per.effective_end_date

LEFT JOIN per_all_assignments_m a
  ON a.person_id = per.person_id
 AND a.primary_flag = 'Y'
 AND TRUNC(SYSDATE) BETWEEN a.effective_start_date AND a.effective_end_date

LEFT JOIN egp_system_items_b etem
  ON etem.inventory_item_id = prl.item_id
 AND etem.organization_id = prl.destination_organization_id

LEFT JOIN po_headers_all poh
  ON poh.po_header_id = prl.po_header_id

LEFT JOIN po_lines_all pol
  ON pol.po_header_id = poh.po_header_id
 AND pol.po_line_id   = prl.po_line_id

LEFT JOIN po_line_locations_all poll
  ON poll.po_header_id = poh.po_header_id
 AND poll.po_line_id   = pol.po_line_id

LEFT JOIN poz_suppliers pos
  ON pos.vendor_id = poh.vendor_id

LEFT JOIN hz_parties hp
  ON hp.party_id = pos.party_id

LEFT JOIN rcv
  ON rcv.po_line_location_id = poll.line_location_id

WHERE
    per.display_name = 'Abraham Saisi'
AND ( :p_requisition_number IS NULL
      OR prh.requisition_number = :p_requisition_number )