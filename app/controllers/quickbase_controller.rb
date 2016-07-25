class QuickbaseController < ApplicationController
require 'will_paginate/array'
  before_action :get_data

  def withholdings
  end

  def index
    respond_to do |format|
      format.json { render json: @final_json }
    end
  end

  def get_data
    state = params["state"] || "CA"
    @state = state
    Quickbase::Connection.username = 'Qbotfxeng@intuit.com'
    Quickbase::Connection.password = 'Intuit123'
    Quickbase::Connection.org = 'intuitcorp'
    app_token = 'cf4hhpsdd9wcqr74t549cc4yp3e'

    agency_form_detail_json = agency_form_detail(app_token, state)
    agency_tax_item_detail_json = agency_tax_item_detail(app_token, state)
    agency_withholding_tax_details_json = agency_withholding_tax_details(app_token, state)
    agency_tax_payment_detail_json = agency_tax_payment_detail(app_token, state)
    tax_payment_frequency_json = tax_payment_frequency(app_token, state)
    electroinc_mandate_requirement_json = electroinc_mandate_requirement(app_token, state)
    agency_tax_rate_json = agency_tax_rate(app_token, state)
    agency_surcharge_json = agency_surcharge(app_token, state)
    pay_stub_requirement_json = pay_stub_requirement(app_token, state)
    agency_local_tax_rate_detail_json = agency_local_tax_rate_detail(app_token, state)
    electronic_form_requirement_json = electronic_form_requirement(app_token, state)
    early_tax_payment_detail_json = early_tax_payment_detail(app_token, state)
    employer_registration_json = employer_registration(app_token, state)

    @final_json = {
      state => {
        "agency_form_detail" => agency_form_detail_json,
        "agency_tax_item_detail" => agency_tax_item_detail_json,
        "agency_withholding_tax_details" => agency_withholding_tax_details_json,
        "agency_tax_payment_detail" => agency_tax_payment_detail_json,
        "tax_payment_frequency" => tax_payment_frequency_json,
        "electroinc_mandate_requirement" => electroinc_mandate_requirement_json,
        "agency_tax_rate" => agency_tax_rate_json,
        "agency_surcharge" => agency_surcharge_json,
        "pay_stub_requirement" => pay_stub_requirement_json,
        "agency_local_tax_rate_detail" => agency_local_tax_rate_detail_json,
        "electronic_form_requirement" => electronic_form_requirement_json,
        "early_tax_payment_detail" => early_tax_payment_detail_json,
        "employer_registration" => employer_registration_json
      }
    }

    @final_json 

  end

  # def history_data()
  #   app_token = 'cf4hhpsdd9wcqr74t549cc4yp3e'
  #   db_id = 'bgav6vyzb'
  #   quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
  #   k = quickbase.api.do_query(:query => "{'6'.CT.'CA'}", :clist => "51")
  #   data = k[1]["51"]
  #   split_data = data.split('--------------') ## Agency Contact Information
  #   length = split_data.count - 1
  #   for i in 1..length
  #   xml_d = split_data[i]
  #     @doc = Nokogiri::XML xml_d 
  #   end
  # end

  def convert_date(data)
    if data.blank?
      nil
    else
      sec = (data.to_f / 1000).to_i
      Time.at(sec.to_i).strftime("%m-%d-%Y")
    end
  end
  
  #region Import Agency Form
  def agency_form_detail(app_token, state)
    db_id = 'bgfs7f3xr'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "27.7.8.34.9.32.11.12.13.17.18.54.33.20.21.22.23.19.53.16.14.15.35.36.24.41.48"
    @agency_form_detail = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    agency_form_detail_json = []
    @agency_form_detail.each do |data|
      data_json = {
        "tax_item_code" => data["27"],
        "agency_tax_form_id" => data["7"],
        "Form_name" => data["8"],
        "associated_form_id" => data["34"],
        "Description" => data["9"],
        "filing_frequency_note" => data["32"],
        "filing_due_date_req_note" => data["11"],
        "non_workday_filing_note" => data["12"],
        "Additional_instrictions_note" => data["13"],
        "file_zero_wage_yn_code" => data["17"],
        "file_zero_liability_yn_code" => data["18"],
        "annual_reconciliation_yn_code" => data["54"],
        "send_w2s_when_filing_yn_code" => data["33"],
        "filing_acknowledge_date_code" => data["20"],
        "filing_acknowledge_date_note" => data["21"],
        "payment_acknowledge_date_code" => data["22"],
        "payment_acknowledge_date_note" => data["23"],
        "quickbooks_form_yn_code" => data["19"],
        "quickbooks_diy_form_id" => data["53"],
        "payment_with_form_yn_code" => data["16"],
        "filing_method_note" => data["14"],
        "payment_method_note" => data["15"],
        "form_detail_effective_date" => convert_date(data["35"]),
        "qb_methods_effective_date" => convert_date(data["36"]),
        "last_verified_date" => convert_date(data["24"]),
        "detail_effective_date_audit" => ImportAgencyFormDetailHistory(data["41"]),
        "qb_methods_effective_date_audit" => ImportAgencyFormQBMethodHistory(data["48"])
      }
      agency_form_detail_json << data_json
    end
    agency_form_detail_json
  end

  def ImportAgencyFormDetailHistory(data)
    array_j = []
    # puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      puts "$$$$$$$$$$$$$"
      puts @doc.xpath("//FilingDueDateReqNot").text
      puts "%%%%%%%%%%%%"
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "TaxFormID" => @doc.xpath("//TaxFormID").text,
          "FormName" => @doc.xpath("//FormName").text,
          "AssociatedTaxFormID" => @doc.xpath("//AssociatedTaxFormID").text,
          "Description" => @doc.xpath("//Description").text,
          "FilingFrequencyNote" => @doc.xpath("//FilingFrequencyNote").text,
          "FilingDueDateReqNot" => @doc.xpath("//FilingDueDateReqNot").text,
          "NonWorkdayFilingNote" => @doc.xpath("//NonWorkdayFilingNote").text,
          "AdditionalInstructionsNote" => @doc.xpath("//AdditionalInstructionsNote").text,
          "SendW2WhenFilingYNCode" => @doc.xpath("//SendW2WhenFilingYNCode").text,
          "FilingZeroWageYNCode" => @doc.xpath("//FilingZeroWageYNCode").text,
          "FilingZeroLiabilityYNCode" => @doc.xpath("//FilingZeroLiabilityYNCode").text,
          "AnnualReconYNCode" => @doc.xpath("//AnnualReconYNCode").text,
          "FilingAckDateCode" => @doc.xpath("//FilingAckDateCode").text,
          "FilingAckDateNote" => @doc.xpath("//FilingAckDateNote").text,
          "PaymentAckDateCode" => @doc.xpath("//PaymentAckDateCode").text,
          "PaymentAckDateNote" => @doc.xpath("//PaymentAckDateNote").text,
          "FormDetailExpirationDate" => @doc.xpath("//FormDetailExpirationDate").text
        }
      }
      # puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyFormQBMethodHistory(data)
    array_j = []
    # puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "TaxFormID" => @doc.xpath("//TaxFormID").text,
          "FormName" => @doc.xpath("//FormName").text,
          "QBFormYNCode" => @doc.xpath("//QBFormYNCode").text,
          "QBDIYFormID" => @doc.xpath("//QBDIYFormID").text,
          "PaymentWithFormYNCode" => @doc.xpath("//PaymentWithFormYNCode").text,
          "FilingMethodNote" => @doc.xpath("//FilingMethodNote").text,
          "PaymentMethodNote" => @doc.xpath("//PaymentMethodNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  # region ImportAgencyWithholdingTax
  def agency_withholding_tax_details(app_token, state)
    tax_details_json = []
    db_id = 'bggi9ejn5'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.27.8.9.20.11.17.18.19.21.22.23.24.25.30.37.14.32.39"
    @agency_withholding_tax_details =  quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_withholding_tax_details.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "calculate_tax_yn_code" => data["27"],
        "allowance_amounts_note" => data["8"],
        "supplemental_rates_note" => data["9"],
        "federal_wh_dependancy_note" => data["20"],
        "round_nearest_dollar_yn_code" => data["11"],
        "qb_diy_requirements_note" => data["17"],
        "qb_assisted_requirements_note" => data["18"],
        "iop_requirements_note" => data["19"],
        "w4_filing_statuses_note" => data["21"],
        "w4_deductible_items_note" => data["22"],
        "w4_rate_requirement_note" => data["23"],
        "w4_additional_req_note" => data["24"],
        "federal_w4_allowed_yn_code" => data["25"],
        "wh_detail_effective_date" => convert_date(data["30"]),
        "w4_effective_date" => convert_date(data["37"]),
        "last_verified_date" => convert_date(data["14"]),
        "wh_effective_date_audit" => ImportAgencyWithholdingHistory(data["32"]),
        "w4_effective_date_audit" => ImportAgencyWithholdingW4History(data["39"])
      }
      tax_details_json << data_json
    end
    tax_details_json
  end

  def ImportAgencyWithholdingHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "CalculateTaxYNCode" => @doc.xpath("//CalculateTaxYNCode").text,
          "AllowanceAmountsNote" => @doc.xpath("//AllowanceAmountsNote").text,
          "SupplementalRatesNote" => @doc.xpath("//SupplementalRatesNote").text,
          "FedWHDependencyNote" => @doc.xpath("//FedWHDependencyNote").text,
          "RoundNearestDollarYNCode" => @doc.xpath("//RoundNearestDollarYNCode").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyWithholdingW4History(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "W4FilingStatusesNote" => @doc.xpath("//W4FilingStatusesNote").text,
          "W4DeductibleItemsNote" => @doc.xpath("//W4DeductibleItemsNote").text,
          "W4RateReqNote" => @doc.xpath("//W4RateReqNote").text,
          "W4AdditionalReqNote" => @doc.xpath("//W4AdditionalReqNote").text,
          "FedW4AllowedYNCode" => @doc.xpath("//FedW4AllowedYNCode").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Agency Tax Payment
  def agency_tax_payment_detail(app_token, state)
    tax_payment_detail_json = []
    db_id = 'bgf2z37z4'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.8.7.9.10.11.12.13.14.18.21"
    @agency_tax_payment_detail =  quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_tax_payment_detail.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["8"],
        "agency_tax_payment_name" => data["7"],
        "pay_zero_ach_credit_note" => data["9"],
        "pay_zero_ach_debit_note" => data["10"],
        "payment_coupon_note" => data["11"],
        "rounding_requirement_note" => data["12"],
        "additional_requirements_note" => data["13"],
        "last_verified_date" => convert_date(data["14"]),
        "payment_detail_effective_date" => convert_date(data["18"]),
        "record_effective_date_audit" => ImportAgencyTaxPaymentHistory(data["21"])
      }
      tax_payment_detail_json << data_json
    end
    tax_payment_detail_json
  end

  def ImportAgencyTaxPaymentHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "TaxPaymentName" => @doc.xpath("//TaxPaymentName").text,
          "PayZeroACHCreditNote" => @doc.xpath("//PayZeroACHCreditNote").text,
          "PayZeroACHDebitNote" => @doc.xpath("//PayZeroACHDebitNote").text,
          "PaymentCouponNote" => @doc.xpath("//PaymentCouponNote").text,
          "RoundingReqNote" => @doc.xpath("//RoundingReqNote").text,
          "AdditionalReqNote" => @doc.xpath("//AdditionalReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end
  
  #region Import Tax Payment Frequency
  def tax_payment_frequency(app_token, state)
    tax_payment_frequency_json = []
    db_id = 'bgf22dkzb'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.19.7.20.9.10.11.12.13.14.15.16.22.25"
    @agency_tax_frequency =  quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_tax_frequency.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["19"],
        "agency_tax_payment_name" => data["7"],
        "tax_payment_frequency_code" => data["20"],
        "frequency_determination_code" => data["9"],
        "freq_det_lookback_req_note" => data["10"],
        "liability_grouping_req_note" => data["11"],
        "tax_payment_due_date_note" => data["12"],
        "holiday_requirement_note" => data["13"],
        "threshold_requirement_note" => data["14"],
        "additional_requirement_note" => data["15"],
        "last_verified_date" => convert_date(data["16"]),
        "pay_frequency_effective_date" => convert_date(data["22"]),
        "record_effective_date_audit" => ImportTaxPaymentFrequencyHistory(data["25"])
      }
      tax_payment_frequency_json << data_json
    end
    tax_payment_frequency_json
  end 

  def ImportTaxPaymentFrequencyHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "TaxPaymentName" => @doc.xpath("//TaxPaymentName").text,
          "TaxPaymentFreqCode" => @doc.xpath("//TaxPaymentFreqCode").text,
          "FreqDeterminationCode" => @doc.xpath("//FreqDeterminationCode").text,
          "FreqDetLookbackReqNote" => @doc.xpath("//FreqDetLookbackReqNote").text,
          "LiabilityGroupingReqNote" => @doc.xpath("//LiabilityGroupingReqNote").text,
          "TaxPaymentDueDateNote" => @doc.xpath("//TaxPaymentDueDateNote").text,
          "HolidayReqNote" => @doc.xpath("//HolidayReqNote").text,
          "ThresholdReqNote" => @doc.xpath("//ThresholdReqNote").text,
          "AdditionalReqNote" => @doc.xpath("//AdditionalReqNote").text,
          "PayFrequencyExpirationDate" => @doc.xpath("//PayFrequencyExpirationDate").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Electronic Mandate Requirements
  def electroinc_mandate_requirement(app_token, state)
    electroinc_mandate_requirement_json = []
    db_id = 'bgg698sf2'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.10.11.15.12.18"
    @electroinc_mandate_requirement =  quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @electroinc_mandate_requirement.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "employer_filing_req_note" => data["8"],
        "employer_payment_req_note" => data["9"],
        "svc_provider_filing_req_note" => data["10"],
        "svc_provider_payment_req_note" => data["11"],
        "mandate_effective_date" => convert_date(data["15"]),
        "last_verified_date" => convert_date(data["12"]),
        "record_effective_date_audit" => ImportElectronicMandateHistory(data["18"])
      }
      electroinc_mandate_requirement_json << data_json
    end
    electroinc_mandate_requirement_json
  end

  def ImportElectronicMandateHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "EmployerFilingReqNote" => @doc.xpath("//EmployerFilingReqNote").text,
          "EmployerPaymentReqNote" => @doc.xpath("//EmployerPaymentReqNote").text,
          "SvcProviderFilingReqNote" => @doc.xpath("//SvcProviderFilingReqNote").text,
          "SvcProviderPaymentReqNote" => @doc.xpath("//SvcProviderPaymentReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Agency Tax Rate
  def agency_tax_rate(app_token, state)
    agency_tax_rate_json = []
    db_id = 'bggisvzur'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "18.19.11.27.28.29.31.32.6.7.8.9.10.12.14.15.16.24.25.50.17.21.38.59.52.45"
    @agency_tax_rate =  quickbase.api.do_query(:query => "{'18'.CT.#{state}}", :clist => @column)
    @agency_tax_rate.each do |data|
      data_json = {
        "agency_code" => data["18"],
        "tax_item_code" => data["19"],
        "new_construction_er_rate_note" => data["11"],
        "qb_diy_requirements_note" => data["27"],
        "qb_assisted_requirements_note" => data["28"],
        "iop_requirements_note" => data["29"],
        "er_limit_freq_calculation_cd" => data["31"],
        "ee_limit_freq_calculation_cd" => data["32"],
        "fixed_employer_amount" => data["6"],
        "fixed_employer_rate" => data["7"],
        "minimum_employer_rate" => data["8"],
        "maximum_employer_rate" => data["9"],
        "new_employer_rate" => data["10"],
        "employer_wage_base_amount" => data["12"],
        "fixed_employee_amount" => data["14"],
        "fixed_employee_rate" => data["15"],
        "employee_wage_base_amount" => data["16"],
        "er_wage_base_effective_date" => convert_date(data["24"]),
        "ee_wage_base_effective_date" => convert_date(data["25"]),
        "er_rate_effective_date" => convert_date(data["50"]),
        "ee_rate_effective_date" => convert_date(data["17"]),
        "last_verified_date" => convert_date(data["21"]),
        "ee_rate_effective_date_audit" => ImportAgencyTaxRateEmployeeRateHistory(data["38"]),
        "ee_wb_effective_date_audit" => ImportAgencyTaxRateEmployeeWageBaseHistory(data["59"]),
        "er_rate_effective_date_audit" => ImportAgencyTaxRateEmployerRateHistory(data["52"]),
        "er_wb_effective_date_audit" => ImportAgencyTaxRateEmployerWageBaseHistory(data["45"])
      }
      agency_tax_rate_json << data_json
    end
    agency_tax_rate_json
  end

  def ImportAgencyTaxRateEmployeeRateHistory(data)
    array_j = []
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "FixedEmployeeAmt" => @doc.xpath("//FixedEmployeeAmt").text,
          "FixedEmployeeRate" => @doc.xpath("//FixedEmployeeRate").text,
          "EELimitFreqCalcCD" => @doc.xpath("//EELimitFreqCalcCD").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyTaxRateEmployeeWageBaseHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "EmployeeWageBaseAmt" => @doc.xpath("//EmployeeWageBaseAmt").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyTaxRateEmployerRateHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "FixedEmployerAmt" => @doc.xpath("//FixedEmployerAmt").text,
          "FixedEmployerRate" => @doc.xpath("//FixedEmployerRate").text,
          "MinEmployerRate" => @doc.xpath("//MinEmployerRate").text,
          "MaxEmployerRate" => @doc.xpath("//MaxEmployerRate").text,
          "NewEmployerRate" => @doc.xpath("//NewEmployerRate").text,
          "NewConstructionERRateNote" => @doc.xpath("//NewConstructionERRateNote").text,
          "ERLimitFreqCalcCD" => @doc.xpath("//ERLimitFreqCalcCD").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyTaxRateEmployerWageBaseHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "EmployerWageBaseAmt" => @doc.xpath("//EmployerWageBaseAmt").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "EELimitFreqCalcCD" => @doc.xpath("//EELimitFreqCalcCD").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Agency Surcharge
  def agency_surcharge(app_token, state)
    agency_surcharge_json = []
    db_id = 'bggitnejf'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.21.12.22.23.24.13.14.15.16.10.11.18.28"
    @agency_surcharge = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_surcharge.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "surcharge_code" => data["8"],
        "surcharge_name" => data["9"],
        "quickbooks_surcharge_yn_code" => data["21"],
        "creditable_to_futa_yn_code" => data["12"],
        "qb_diy_requirements_note" => data["22"],
        "qb_assisted_requirements_note" => data["23"],
        "iop_requirements_note" => data["24"],
        "fixed_employer_rate" => data["13"],
        "minimum_employer_rate" => data["14"],
        "maximum_employer_rate" => data["15"],
        "employer_wage_base_amount" => data["16"],
        "surcharge_effective_date" => convert_date(data["10"]),
        "surcharge_expiration_date" => convert_date(data["11"]),
        "last_verified_date" => convert_date(data["18"]),
        "record_effective_date_audit" => ImportAgencySurchargeHistory(data["28"])
      }
      agency_surcharge_json << data_json
    end
    agency_surcharge_json
  end

  def ImportAgencySurchargeHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "SurchargeName" => @doc.xpath("//SurchargeName").text,
          "SurchargeCode" => @doc.xpath("//SurchargeCode").text,
          "QBSurchargeYNCode" => @doc.xpath("//QBSurchargeYNCode").text,
          "CreditableFutaYNCode" => @doc.xpath("//CreditableFutaYNCode").text,
          "FixedEmployerRate" => @doc.xpath("//FixedEmployerRate").text,
          "MinEmployerRate" => @doc.xpath("//MinEmployerRate").text,
          "MaxEmployerRate" => @doc.xpath("//MaxEmployerRate").text,
          "EmployerWageBaseAmt" => @doc.xpath("//EmployerWageBaseAmt").text,
          "SurchargeExpirationDate" => @doc.xpath("//SurchargeExpirationDate").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Pay Stub
  def pay_stub_requirement(app_token, state)
    pay_stub_requirement_json = []
    db_id = 'bgh5wu2n8'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.15.10.18"
    @pay_stub_requirement = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @pay_stub_requirement.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "general_delivery_req_note" => data["7"],
        "electronic_delivery_req_note" => data["8"],
        "paper_deliver_req_note" => data["9"],
        "pay_stub_effective_date" => convert_date(data["15"]),
        "last_verified_date" => convert_date(data["10"]),
        "record_effective_date_audit" => ImportPayStubHistory(data["18"])
      }
      pay_stub_requirement_json << data_json
    end
    pay_stub_requirement_json
  end

  def ImportPayStubHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "GeneralDeliveryReqNote" => @doc.xpath("//GeneralDeliveryReqNote").text,
          "ElectronicDeliveryReqNote" => @doc.xpath("//ElectronicDeliveryReqNote").text,
          "PaperDeliveryReqNote" => @doc.xpath("//PaperDeliveryReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  # region ImportAgencyLocalTaxRate
  def agency_local_tax_rate_detail(app_token, state)
    agency_local_tax_rate_detail_json = []
    db_id = 'bgi8bfvzi'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.10.11.15.13.14.26.27.28.12.16.21"
    @agency_local_tax_rate_detail = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_local_tax_rate_detail.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "local_tax_name" => data["8"],
        "local_tax_purpose_note" => data["9"],
        "responsible_party_code" => data["10"],
        "tax_rate_note" => data["11"],
        "additional_requirements_note" => data["15"],
        "allowance_amounts_note" => data["13"],
        "tax_calculation_note" => data["14"],
        "qb_diy_requirements_note" => data["26"],
        "qb_assisted_requirements_note" => data["27"],
        "iop_requirements_note" => data["28"],
        "tax_rate_effective_date" => convert_date(data["12"]),
        "last_verified_date" => convert_date(data["16"]),
        "record_effective_date_audit" => ImportAgencyLocalTaxRateHistory(data["21"])
      }
      agency_local_tax_rate_detail_json << data_json
    end
    agency_local_tax_rate_detail_json
  end

  def ImportAgencyLocalTaxRateHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "LocalTaxName" => @doc.xpath("//LocalTaxName").text,
          "LocalTaxPurposeNote" => @doc.xpath("//LocalTaxPurposeNote").text,
          "ResponsiblePartyCode" => @doc.xpath("//ResponsiblePartyCode").text,
          "TaxRateNote" => @doc.xpath("//TaxRateNote").text,
          "AllowanceAmtNote" => @doc.xpath("//AllowanceAmtNote").text,
          "TaxCalculationNote" => @doc.xpath("//TaxCalculationNote").text,
          "AdditionalReqNote" => @doc.xpath("//AdditionalReqNote").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text,
          "QBAssistedReqNote" => @doc.xpath("//QBAssistedReqNote").text,
          "IOPReqNote" => @doc.xpath("//IOPReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Electronic Form Requirement
  def electronic_form_requirement(app_token, state)
    electronic_form_requirement_json = []
    db_id = 'bgfs8w5f2'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.19.20.8.9.10.11.12.13.14.15.21.16.24"
    @electronic_form_requirement = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @electronic_form_requirement.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["19"],
        "agency_tax_form_id" => data["20"],
        "filing_enrollment_note" => data["8"],
        "payment_enrollment_note" => data["9"],
        "login_requirement_note" => data["10"],
        "additional_login_detail_note" => data["11"],
        "bank_acct_change_note" => data["12"],
        "penalty_interest_req_note" => data["13"],
        "penalty_interest_howto_note" => data["14"],
        "alternative_submission_note" => data["15"],
        "e_form_req_effective_date" => convert_date(data["21"]),
        "last_verified_date" => convert_date(data["16"]),
        "record_effective_date_audit" => ImportElectronicFormReqsHistory(data["24"])
      }
      electronic_form_requirement_json << data_json
    end
    electronic_form_requirement_json
  end

  def ImportElectronicFormReqsHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "TaxFormID" => @doc.xpath("//TaxFormID").text,
          "FilingEnrollmentNote" => @doc.xpath("//FilingEnrollmentNote").text,
          "PaymentEnrollmentNote" => @doc.xpath("//PaymentEnrollmentNote").text,
          "LoginReqNote" => @doc.xpath("//LoginReqNote").text,
          "AddtionalLoginDetailNote" => @doc.xpath("//AddtionalLoginDetailNote").text,
          "BankAcctChangeNote" => @doc.xpath("//BankAcctChangeNote").text,
          "PenaltyInterestReqNote" => @doc.xpath("//PenaltyInterestReqNote").text,
          "PenaltyInterestHowtoNote" => @doc.xpath("//PenaltyInterestHowtoNote").text,
          "AltSubmissionNote" => @doc.xpath("//AltSubmissionNote").text,
          "EFormReqExpirationDate" => @doc.xpath("//EFormReqExpirationDate").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Early Tax Payment
  def early_tax_payment_detail(app_token, state)
    early_tax_payment_detail_json = []
    db_id = 'bgf22pwyf'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "21.22.6.7.8.9.10.11.12.13.14.15.16.17.24.23.25.18.28"
    @early_tax_payment_detail = quickbase.api.do_query(:query => "{'21'.CT.#{state}}", :clist => @column)
    @early_tax_payment_detail.each do |data|
      data_json = {
        "agency_code" => data["21"],
        "tax_item_code" => data["22"],
        "eft_eligibility_note" => data["6"],
        "eft_process_note" => data["7"],
        "eft_communication_note" => data["8"],
        "eft_form_note" => data["9"],
        "eft_timing_note" => data["10"],
        "eft_known_sys_impacts_note" => data["11"],
        "check_eligibility_note" => data["12"],
        "check_process_note" => data["13"],
        "check_communication_note" => data["14"],
        "check_form_note" => data["15"],
        "check_timing_note" => data["16"],
        "check_known_sys_impacts_note" => data["17"],
        "qb_diy_requirements_note" => data["24"],
        "qb_feature_cancelled_date" => convert_date(data["23"]),
        "early_pay_effective_date" => convert_date(data["25"]),
        "last_verified_date" => convert_date(data["18"]),
        "record_effective_date_audit" => ImportEarlyTaxPaymentHistory(data["28"])
      }
      early_tax_payment_detail_json << data_json
    end
    early_tax_payment_detail_json
  end

  def ImportEarlyTaxPaymentHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "QBFeatureCancelDate" => @doc.xpath("//QBFeatureCancelDate").text,
          "EFTEligibilityNote" => @doc.xpath("//EFTEligibilityNote").text,
          "EFTProcessNote" => @doc.xpath("//EFTProcessNote").text,
          "EFTCommunicationNote" => @doc.xpath("//EFTCommunicationNote").text,
          "EFTFormNote" => @doc.xpath("//EFTFormNote").text,
          "EFTTimingNote" => @doc.xpath("//EFTTimingNote").text,
          "EFTSysImpactsNote" => @doc.xpath("//EFTSysImpactsNote").text,
          "ChkEligibilityNote" => @doc.xpath("//ChkEligibilityNote").text,
          "ChkProcessNote" => @doc.xpath("//ChkProcessNote").text,
          "ChkCommunicationNote" => @doc.xpath("//ChkCommunicationNote").text,
          "ChkTimingNote" => @doc.xpath("//ChkTimingNote").text,
          "ChkFormNote" => @doc.xpath("//ChkFormNote").text,
          "ChkSysImpactsNote" => @doc.xpath("//ChkSysImpactsNote").text,
          "QBDIYReqNote" => @doc.xpath("//QBDIYReqNote").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  #region Import Agency Tax Item
  def agency_tax_item_detail(app_token, state)
    agency_tax_item_detail_json = []
    db_id = 'bgav6vyzb'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.10.11.21.38.13.23.14.39.22.16.41.43.56.19.51.65.58.70"
    @agency_tax_item_detail = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @agency_tax_item_detail.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "agency_tax_item_name" => data["8"],
        "vendor_payable_name" => data["9"],
        "office_full_mailing_address" => data["10"],
        "office_phone_number_detail" => data["11"],
        "customer_support_email_id" => data["21"],
        "account_number_name" => data["38"],
        "quickbooks_er_acct_num_format" => data["13"],
        "additional_er_acct_num_format" => data["23"],
        "legal_holidays_observed_note" => data["14"],
        "reporting_codes_req_note" => data["39"],
        "customer_support_url" => data["22"],
        "agency_tax_item_website_url" => data["16"],
        "employer_guide_url" => data["70"],
        "agency_detail_effective_date" => convert_date(data["41"]),
        "account_number_effective_date" => convert_date(data["43"]),
        "holiday_effective_date" => convert_date(data["56"]),
        "last_verified_date" => convert_date(data["19"]),
        "detail_effective_date_audit" => ImportAgencyTaxItemDetailHistory(data["51"]),
        "acct_num_effective_date_audit" => ImportAgencyTaxItemAccountNumberHistory(data["65"]),
        "holiday_effective_date_audit" => ImportAgencyTaxItemHolidayHistory(data["58"])
      }
      agency_tax_item_detail_json << data_json
    end
    agency_tax_item_detail_json
  end

  def ImportAgencyTaxItemDetailHistory(data)
    array_j = []
    # k = quickbase.api.do_query(:query => "{'6'.CT.'CA'}", :clist => "51")
    # data = k[1]["51"]
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') ## Agency Contact Information
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
        @doc = Nokogiri::XML xml_d 
        cjson = { 
          "DataChangeAudit" => {
            "DataRecordName" => @doc.xpath("//DataRecordName").text,
            "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
            "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
            "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
            "VendorPayableName" => @doc.xpath("//VendorPayableName").text,
            "MailingAddress" => @doc.xpath("//MailingAddress").text,
            "PhoneNumbers" => @doc.xpath("//PhoneNumbers").text,
            "CustomerSupportEmail" => @doc.xpath("//CustomerSupportEmail").text,
            "CustomerSuportURL" => @doc.xpath("//CustomerSuportURL").text,
            "AgencyWebsiteName" => @doc.xpath("//AgencyWebsiteName").text,
            "AgencyWebsiteURL" => @doc.xpath("//AgencyWebsiteURL").text,
            "ReportCodeRequirements" => @doc.xpath("//ReportCodeRequirements").text
          }
        }
        puts "@@@@@", cjson
        array_j << cjson
      end
      array_j
  end

  def ImportAgencyTaxItemAccountNumberHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "DataEffectiveDate" => @doc.xpath("//DataEffectiveDate").text,
          "AccountNumberName" => @doc.xpath("//AccountNumberName").text,
          "QBERAcctNumFormat" => @doc.xpath("//QBERAcctNumFormat").text,
          "PhoneNumbers" => @doc.xpath("//PhoneNumbers").text,
          "AddtnlERAcctNumFormat" => @doc.xpath("//CustomerSupportEmail").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end

  def ImportAgencyTaxItemHolidayHistory(data)
    array_j = []
    puts "@@@@@@@@@", data.inspect
    split_data = data.split('--------------') 
    length = split_data.count - 1
    for i in 1..length
      xml_d = split_data[i]
      @doc = Nokogiri::XML xml_d 
      cjson = { 
        "DataChangeAudit" => {
          "DataRecordName" => @doc.xpath("//DataRecordName").text,
          "DateTimeModified" => @doc.xpath("//DateTimeModified").text,
          "ModifiedByUser" => @doc.xpath("//ModifiedByUser").text,
          "HolidaysObservedNote" => @doc.xpath("//HolidaysObservedNote").text,
          "HolidayEffectiveDate" => @doc.xpath("//DataEffectiveDate").text
        }
      }
      puts "@@@@@", cjson
      array_j << cjson
    end
    array_j
  end



  ###
  def employer_registration(app_token, state)
    employer_registration_json = []
    db_id = 'bhmqqyasx'
    quickbase = Quickbase::Connection.new(:apptoken => app_token, :dbid => db_id)
    @column = "6.7.8.9.10.11.12.15.16.17"
    @employer_registration = quickbase.api.do_query(:query => "{'6'.CT.#{state}}", :clist => @column)
    @employer_registration.each do |data|
      data_json = {
        "agency_code" => data["6"],
        "tax_item_code" => data["7"],
        "preferred_method_code" => data["8"],
        "registration_process_url" => data["9"],
        "fee_yn_code" => data["10"],
        "form_name" => data["11"],
        "form_url" => data["12"],
        "general_registration_note" => data["15"],
        "requirements_effective_date" => convert_date(data["16"]),
        "last_verified_date" => convert_date(data["17"])
      }
      employer_registration_json << data_json
    end
    employer_registration_json
  end









  # GET /dashboards/1
  # GET /dashboards/1.json
  def show
  end

  # GET /dashboards/new
  def new
    @dashboard = Dashboard.new
  end

  # GET /dashboards/1/edit
  def edit
  end

  # POST /dashboards
  # POST /dashboards.json
  def create
    @dashboard = Dashboard.new(dashboard_params)

    respond_to do |format|
      if @dashboard.save
        format.html { redirect_to @dashboard, notice: 'Dashboard was successfully created.' }
        format.json { render :show, status: :created, location: @dashboard }
      else
        format.html { render :new }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboards/1
  # PATCH/PUT /dashboards/1.json
  def update
    respond_to do |format|
      if @dashboard.update(dashboard_params)
        format.html { redirect_to @dashboard, notice: 'Dashboard was successfully updated.' }
        format.json { render :show, status: :ok, location: @dashboard }
      else
        format.html { render :edit }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboards/1
  # DELETE /dashboards/1.json
  def destroy
    @dashboard.destroy
    respond_to do |format|
      format.html { redirect_to dashboards_url, notice: 'Dashboard was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboard
      @dashboard = Dashboard.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dashboard_params
      params.require(:dashboard).permit(:name)
    end
end
