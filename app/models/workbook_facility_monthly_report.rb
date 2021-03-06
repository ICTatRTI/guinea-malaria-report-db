class WorkbookFacilityMonthlyReport < ActiveRecord::Base
  include DateHelper

  belongs_to :workbook_file
  belongs_to :health_facility
  has_many :workbook_facility_inventory_reports
  has_many :workbook_facility_malaria_group_reports
  
  CELL_FACILITY_NAME = ['D', 4]

  # Import the passed in sheet for the workbook_file.  Create the reports if they
  # don't exist.  Any errors should be exceptions that roll back the entire 
  # transaction
  def self.import_sheet! workbook_file, sheet, sheet_name
    health_facility_name = sheet.cell(*CELL_FACILITY_NAME)
    district = workbook_file.workbook.district
    health_facility = workbook_file.get_health_facility_override(sheet_name) || 
      HealthFacility.district_named(district, health_facility_name)
    raise "No health facility named '#{health_facility_name}' found" unless health_facility

    report = WorkbookFacilityMonthlyReport.report_for workbook_file, health_facility
    report.apply_sheet! sheet
  end

  def self.report_for workbook_file, health_facility
    props = {
      workbook_file: workbook_file, 
      health_facility: health_facility
    }
    where(props).first || WorkbookFacilityMonthlyReport.new(props)
  end

  def apply_sheet! sheet
    self.population_total               = sheet.cell('J', 3)
    self.population_covered             = sheet.cell('J', 4)
    self.num_services                   = sheet.cell('U', 3)
    self.num_reports_compiled           = sheet.cell('U', 4)
    self.num_pregnant_anc_tested        = sheet.cell('H', 26)
    self.num_pregnant_first_dose_sp     = sheet.cell('H', 27)
    self.num_pregnant_three_doses_sp    = sheet.cell('H', 29)
    self.num_structures                 = sheet.cell('L', 29)
    self.num_agents                     = sheet.cell('O', 29)
    self.num_local_ngos_cbos            = sheet.cell('S', 29)
    self.compiled_by_name               = sheet.cell('D', 47)
    self.compiled_by_org                = sheet.cell('D', 48)
    self.compiled_by_phone              = sheet.cell('I', 47)
    self.approved_by_name               = sheet.cell('O', 47)
    self.approved_by_org                = sheet.cell('O', 48)
    self.approved_by_phone              = sheet.cell('U', 47)

    self.num_pregnant_second_dose_sp    = sheet.cell('H', 28)
    self.num_pregnant_fourth_dose_sp    = sheet.cell('H', 30)
    self.num_awareness_session          = sheet.cell('H', 31)
    self.llin_dist_cpn                  = sheet.cell('H', 32)
    self.llin_dist_pev                  = sheet.cell('H', 33)

    self.compiled_by_date               = sheet.cell('I', 48)
    if !compiled_by_date.blank? && !is_a_date?(compiled_by_date)
      self.compiled_by_date = nil
    end 

    self.approved_by_date               = sheet.cell('U', 48)
    if !approved_by_date.blank? && !is_a_date?(approved_by_date)
      self.approved_by_date = nil
    end 

    # Apply workbook to Malaria Group Reports
    WorkbookFacilityMalariaGroupReport::GROUPS.each do |g|
      WorkbookFacilityMalariaGroupReport::REGISTRATIONS.each do |r|
        group_report = WorkbookFacilityMalariaGroupReport.report_for self, g, r
        group_report.apply_sheet! sheet
      end      
    end

    # Apply workbook to Inventory Reports
    WorkbookFacilityInventoryReport.sheet_products(sheet).each do |product|
      inventory_report = WorkbookFacilityInventoryReport.report_for self, product
      inventory_report.apply_sheet! sheet
    end

    self.save!
  end

end
