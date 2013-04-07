require 'model_spec_helper'

describe Revision do

  it "requires locale" do
    expect(Fabricate.build(:revision, locale: '')).to have_errors_on :locale
  end

  it "requires title" do
    expect(Fabricate.build(:revision, title: '')).to have_errors_on :title
  end

  it "requires content" do
    expect(Fabricate.build(:revision, content: '')).to have_errors_on :content
  end

  it "requires author" do
    expect(Fabricate.build(:revision, author: nil)).to have_errors_on :author
  end

  it "requires article" do
    expect(Fabricate.build(:revision, article: nil)).to have_errors_on :article
  end

  describe "#pending" do
    it "returns the most recent pending versions" do
      article = Fabricate(:article)
      a = Fabricate(:revision, approved: true, locale: :it, created_at: 4.days.ago, article: article)
      b = Fabricate(:revision, approved: false, locale: :it, created_at: 3.days.ago, article: article)
      c = Fabricate(:revision, approved: false, locale: :it, created_at: 2.days.ago, article: article)
      d = Fabricate(:revision, approved: nil, locale: :en, created_at: 3.days.ago, article: article)
      e = Fabricate(:revision, approved: true, locale: :fr, created_at: 3.days.ago, article: article)

     expect(Revision.pending).to eq([ d, c ])
    end
  end

  describe ".status" do
    it "returns the status of a version" do
      article = Fabricate(:article)
      a = Fabricate(:revision, approved: true, locale: :it, created_at: 4.days.ago, article: article)
      b = Fabricate(:revision, approved: false, locale: :it, created_at: 3.days.ago, article: article)
      c = Fabricate(:revision, approved: true, locale: :it, created_at: 2.days.ago, article: article)
      d = Fabricate(:revision, approved: false, locale: :it, created_at: 2.days.ago, article: article)

      expect(a.status).to eq(Revision::STATUS_APPROVED)
      expect(b.status).to eq(Revision::STATUS_SKIPPED)
      expect(c.status).to eq(Revision::STATUS_PUBLIC)
      expect(d.status).to eq(Revision::STATUS_PENDING)
    end
  end

  describe "#build" do
    it "builds a new revision for a new article" do
      user = Fabricate(:user)
      revision = Revision.build("en", user, title: 'Title', category: 'getting-started')
      expect(revision.locale).to eq(:en)
      expect(revision.author).to eq(user)
      expect(revision.title).to eq('Title')
      expect(revision.article).to be_present
      expect(revision.article).to be_new_record
    end
  end

  describe ".build_updated" do
    let(:revision) { Fabricate(:revision, locale: "en") }
    let(:author) { revision.author }
    let(:user) { Fabricate(:user) }

    context "when the author changes" do
      it "duplicates the revision" do
        new_revision = revision.build_updated(user, title: 'Title')
        expect(new_revision).to_not eq revision
        expect(new_revision.locale).to eq(:en)
        expect(new_revision.title).to eq('Title')
        expect(new_revision.article).to eq(revision.article)
      end
    end

    context "when the locale changes" do
      it "duplicates the revision" do
        new_revision = revision.build_updated(author, title: 'Titolo', locale: "it")
        expect(new_revision).to_not eq revision
        expect(new_revision.locale).to eq(:it)
        expect(new_revision.title).to eq('Titolo')
        expect(new_revision.article).to eq(revision.article)
      end
    end

    context "when the revision is already approved" do
      it "updates the revision" do
        revision.approve!
        new_revision = revision.build_updated(author, title: 'Title')
        expect(new_revision).to_not eq revision
        expect(new_revision.locale).to eq(:en)
        expect(new_revision.title).to eq('Title')
        expect(new_revision.article).to eq(revision.article)
      end
    end

    context "else" do
      it "updates the revision" do
        new_revision = revision.build_updated(author, title: 'Title')
        expect(new_revision).to eq revision
        expect(new_revision.title).to eq('Title')
      end
    end
  end

  describe ".destroy!" do
    it "destroys the revision (also the article if empty)" do
      revision = Fabricate(:revision)
      article = revision.article
      second_revision = Fabricate(:revision, article: article)

      revision.destroy!
      expect(Article.exists?(article.id)).to be_true
      expect(Revision.exists?(revision.id)).to be_false

      second_revision.destroy!
      expect(Article.exists?(article.id)).to be_false
      expect(Revision.exists?(second_revision.id)).to be_false
    end
  end

end

