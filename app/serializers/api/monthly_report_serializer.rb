class Api::MonthlyReportSerializer
  def self.call(monthly_report)
    {
      id: monthly_report.id,
      title: monthly_report.title,
      description: monthly_report.description,
      state: monthly_report.state,
      completed_at: monthly_report.completed_at&.iso8601,
      # Short-lived service URL (same idiom as the orders view); nil when no image is attached.
      image_url: monthly_report.image.attached? ? monthly_report.image.url : nil,
      image_filename: monthly_report.image.attached? ? monthly_report.image.filename.to_s : nil,
      # Not always an image — scans are uploaded as PDFs.
      image_content_type: monthly_report.image.attached? ? monthly_report.image.content_type : nil,
      created_at: monthly_report.created_at&.iso8601
    }
  end
end
