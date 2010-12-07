ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.module_eval do
  def jquery(&block)
    @lines << "(function($) {"
    block.call(page)
    @lines << "})(jQuery);"
  end
end