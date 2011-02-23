FireWatir::Firefox.class_eval do
  def url
    @window_url = js_eval "#{document_var}.URL"
  end

  def status
    js_status = js_eval("window.status")
    js_status.empty? ? js_eval("window.XULBrowserWindow.statusText;") : js_status
  end
end
