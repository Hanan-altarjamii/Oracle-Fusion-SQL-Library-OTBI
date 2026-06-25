
SELECT

    papf.person_number employee_number,         -- Employee ID / Number
    ppnf.full_name employee_name,               -- Employee Full Name

    papf_s.person_number manager_emp_number,    -- Manager Employee Number
    ppnf_s.full_name manager_name               -- Manager Full Name

FROM 

     per_all_people_f papf,
     per_person_names_f ppnf,
     per_all_assignments_m paam,
     per_assignment_supervisors_f pasf,
     per_all_people_f papf_s,
     per_person_names_f ppnf_s,
     per_all_assignments_m paam_s
     


WHERE papf.person_id = ppnf.person_id
  AND papf.person_id = paam.person_id
  AND papf.person_id = pasf.person_id
  AND paam.assignment_id = pasf.assignment_id

  -- Link employee assignment to manager assignment
  AND pasf.manager_assignment_id = paam_s.assignment_id

  -- Link manager person details
  AND pasf.manager_id = papf_s.person_id
  AND papf_s.person_id = ppnf_s.person_id

  -- Ensure global name type for both employee and manager
  AND ppnf.name_type = 'GLOBAL'
  AND ppnf_s.name_type = 'GLOBAL'

  -- Effective date filters (current records only)
  AND SYSDATE BETWEEN ppnf.effective_start_date AND ppnf.effective_end_date
  AND SYSDATE BETWEEN ppnf_s.effective_start_date AND ppnf_s.effective_end_date
  AND SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
  AND SYSDATE BETWEEN papf_s.effective_start_date AND papf_s.effective_end_date
  AND SYSDATE BETWEEN paam.effective_start_date AND paam.effective_end_date
  AND SYSDATE BETWEEN paam_s.effective_start_date AND paam_s.effective_end_date
  AND SYSDATE BETWEEN pasf.effective_start_date AND pasf.effective_end_date