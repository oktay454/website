require 'spec_helper'

describe Article do

  it { should_not allow_value('').for(:category) }

  describe "#available_locales" do
    it "returns all the locales for which is present an approved revision" do
      article = create(:article)
      create(:revision, approved: true, locale: :it, article: article)
      create(:revision, approved: true, locale: :it, article: article)
      create(:revision, approved: false, locale: :en, article: article)

      expect(article.available_locales).to eq([ :it ])
    end
  end

  describe "#latest_revision and #public_revision" do
    it "returns the latest revision available for a locale" do
      a = create(:article)
      recent_revision = create(:revision, approved: false, locale: :it, created_at: 2.days.ago, article: a)
      old_revision    = create(:revision, approved: true, locale: :it, created_at: 3.days.ago, article: a)

      expect(a.latest_revision(:it)).to eq(recent_revision)
      expect(a.public_revision(:it)).to eq(old_revision)
    end
  end

  describe "#with_public_revisions" do
    it "returns only articles with at least an approved revision" do
      article = create(:article)
      create(:revision, approved: true, locale: :it, article: article)
      create(:revision, approved: true, locale: :it, created_at: 3.days.ago, article: article)
      create(:revision, approved: false, locale: :en, article: article)

      expect(Article.with_public_revisions(:it)).to eq([ article ])
      expect(Article.with_public_revisions(:fr)).to be_empty
      expect(Article.with_public_revisions(:en)).to be_empty
    end
  end

end

