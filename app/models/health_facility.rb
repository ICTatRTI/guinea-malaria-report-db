class HealthFacility < ActiveRecord::Base
  belongs_to :district

  def self.district_named district, name
    return nil if name.blank?
    where("district_id = :district_id", district_id: district.id) 
      .where("lower(name) = :name OR :name = ANY(lower(alternative_names::text)::text[])", 
        name: name.mb_chars.strip.downcase)
      .where(end_date: nil)
      .first
  end

  def dhis2_id
    "FAC#{id.to_s.rjust(8, '0')}"
  end

end
