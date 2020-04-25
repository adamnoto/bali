describe Bali::Printer do
  before do
    allow(DateTime).to receive(:now).and_return(DateTime.parse("01-01-2020 12:34AM +00:00"))
  end

  def expect_fixture_match text, fixture_name
    fixture_path = File.expand_path(__FILE__ + "/../fixtures/#{fixture_name}")
    # binding.pry

    if File.exists? fixture_path
      expect(text).to eq File.read(fixture_path)
    else
      File.write(fixture_path, text)
    end
  end

  it "match with the fixture" do
    text = Bali::Printer.pretty_print
    expect_fixture_match text, "pretty_print.txt"
  end
end
