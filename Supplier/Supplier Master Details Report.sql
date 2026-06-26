
SELECT 

    bus.bu_name AS Business_unit, -- Business Unit Name
    psv.vendor_name AS supplier_name, -- Supplier Name (English)
    psv.VENDOR_NAME_ALT AS Arabic_Name, -- Supplier Name (Arabic / Alternate)
    psv.BUSINESS_RELATIONSHIP AS BUSINESS_RELATIONSHIP, -- Supplier Business Relationship Type
    psv.VENDOR_TYPE_LOOKUP_CODE AS Supplier_Type, -- Supplier Type Classification
    psv.segment1 AS supplier_number, -- Supplier Unique Number
    pascv.name AS contact_person, -- Supplier Contact Person Name
    pascv.email_address AS contact_email, -- Contact Email Address  
    pascv.phone_country_code || ' ' || pascv.phone_extension || ' ' || pascv.phone_number AS contact_phone_full,

    -- Full Contact Phone (Country Code + Extension + Number)

    pssv.vendor_site_code AS site_code, -- Supplier Site Code
    pssv.address_line1 || ' ' || pssv.address_line2 || ' ' || pssv.address_line3 || ' ' || pssv.address_line4 
    || ' ' || pssv.city || ' ' || pssv.state || ' ' || pssv.country || ' ' || pssv.county AS site_full_address,
	

    -- Full Supplier Site Address 

	pssv.province AS site_province, -- Province / Region of Supplier Site
    pssv.zip AS zip_code, -- Postal Code
    hpp.attribute1 AS user_defined_roles, -- Custom User Defined Roles Attribute
    pssv.party_site_name AS site_location_name, -- Supplier Site Location Name 

	(
        SELECT atv.name
        FROM ap_terms_vl atv
        WHERE atv.term_id = pssv.terms_id 
          AND ROWNUM = 1
    ) AS payment_term_name,

    -- Payment Terms Name (Lookup from Terms Table)

    pssv.attribute1 AS facility_mill_id, -- Custom Attribute: Facility / Mill ID
    pssv.attribute4 AS legacy_system_reference, -- Legacy System Reference ID
    pssv.attribute2 AS internal_supplier_notes, -- Internal Notes for Supplier Site
    pssv.creation_date AS site_created_on, -- Site Creation Date
    pascv.creation_date AS contact_created_on, -- Contact Creation Date

    CASE 
        WHEN psv.enabled_flag = 'Y' THEN 'Active' 
        ELSE 'Inactive' 
    END AS supplier_account_status, 

    -- Supplier Account Status Based on Enabled Flag
    CASE 
        WHEN NVL(pssv.inactive_date, SYSDATE + 1) > SYSDATE THEN 'Active' 
        ELSE 'Inactive' 
    END AS site_operating_status,
    -- Supplier Site Operating Status Based on Inactive Date

    CASE 
        WHEN NVL(psav.inactive_date, SYSDATE + 1) > SYSDATE THEN 'Active' 
        ELSE 'Inactive' 
    END AS address_validity_status
    -- Supplier Address Validity Status

FROM

    poz_all_supplier_contacts_v pascv,
    poz_supplier_address_v psav,
    poz_suppliers_v psv,
    fun_all_business_units_v bus,
    poz_supplier_sites_v pssv,
    hz_person_profiles hpp

WHERE

    pascv.sup_party_id = psav.party_id
    AND psv.vendor_id = psav.vendor_id
    AND psav.vendor_id = pssv.vendor_id
    AND psv.party_id = pascv.sup_party_id
    AND bus.bu_id = pssv.prc_bu_id
    AND psav.location_id = pssv.location_id
    AND psv.vendor_id = pssv.vendor_id
    AND pascv.per_party_id = hpp.party_id

ORDER BY
    psv.vendor_name ASC -- Sort Suppliers Alphabetically by Name