# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe Room do
  share_examples_for '妥当でない部屋'  do
    its(:save) { should be_false }
    its(:validate) { should be_false }
  end

  context "タイトルが空" do
    subject{ Room.new(:title => '') }
    it_should_behave_like '妥当でない部屋'
  end
  context "タイトルがnil" do
    subject{ Room.new(:title => nil) }
    it_should_behave_like '妥当でない部屋'
  end
  context "初期状態" do
    subject { Room.new }
    it_should_behave_like '妥当でない部屋'
  end

  describe "all_live" do
    before(:each) do
      Room.delete_all
    end

    context "rooms が空" do
      subject { Room.all_live }
      it { should have(0).records }
    end

    context "rooms が2個" do
      before do
        Room.new(:title => 'room1', :user => nil, :updated_at => Time.now).save
        Room.new(:title => 'room2', :user => nil, :updated_at => Time.now).save
      end

      subject { Room.all_live }
      it { should have(2).records }
    end

    context "rooms が2個かつ1個削除されている" do
      before do
        Room.new(:title => 'room1', :user => nil, :updated_at => Time.now).save!
        room = Room.new(:title => 'room2', :user => nil, :updated_at => Time.now)
        room.deleted = true
        room.save!
      end

      subject { Room.all_live }
      it { should have(1).records }
    end
  end

  before {
    @user = User.new
    @room = Room.new(:title => 'room1', :user => @user, :updated_at => Time.now)
  }
  describe "to_json" do
    subject { @room.to_json }
    its([:name]) { should == "room1" }
    its([:user])  { should == @user.to_json }
    its([:updated_at]) { should == @room.updated_at.to_s }
  end

  describe "yaml field" do
    before  { @room.yaml = { 'foo' => 'baz' } }
    subject { @room.yaml }
    its(['foo']) { should == 'baz' }
    it{ should have(1).items }
  end

  describe "messages" do
    before do
      @messages = (0..10).map do|i|
        Message.new(:body => "body of message #{i}",
                    :room => @room).tap{|m| m.save! }
      end
    end
    describe "messages" do
      subject { @room.messages(5) }
      it { should have(5).items }
      it { should == @messages[6..-1] }
    end

    describe "messages_between" do
      subject { between = @room.messages_between(@messages[3].id, @messages[5].id, 2) }
      it { should == [@messages[3], @messages[4]] }
    end
  end

  describe "accessible?" do
    context "publicな部屋" do
      before {
        @room = Room.create(:title => 'room public', :user => @user, :is_public => true)
      }

      subject { @room.accessible?(@user) }
      it { should be_true }
    end

    context "privateな部屋" do
      before do
        @member = User.create
        @other = User.create
        @room = Room.create(:title => 'room public', :user => @user, :is_public => false)
        @room.members << @member
      end

      context "owner" do
        subject { @room.accessible? @user }
        it { should be_true }
      end

      context "member" do
        subject { @room.accessible? @member }
        it { should be_true }
      end

      context "その他" do
        subject { @room.accessible? @other }
        it { should be_false }
      end
    end
  end
end
