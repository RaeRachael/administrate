require "rails_helper"

describe "fields/has_one/_index", type: :view do
  context "without an associated record" do
    it "displays nothing" do
      has_one = Administrate::Field::HasOne.new(
        :product_meta_tag,
        build(:product_meta_tag),
        :index,
      )

      render(
        partial: "fields/has_one/index",
        locals: { field: has_one },
      )

      expect(rendered.strip).to eq("")
    end
  end

  context "with an associated record" do
    it "renders a link to the record" do
      product = create(:product)
      product_path = polymorphic_path([:admin, product])
      has_one = instance_double(
        "Administrate::Field::HasOne",
        data: product,
        linkable?: true,
        display_associated_resource: product.name,
      )

      render(
        partial: "fields/has_one/index",
        locals: { field: has_one, namespace: "admin" },
      )

      expected = "<a href=\"#{product_path}\">#{product.name}</a>"
      expect(rendered.strip).to eq(expected)
    end
  end
end
