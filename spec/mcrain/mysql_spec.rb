# coding: utf-8
require 'spec_helper'

require 'tmpdir'

describe Mcrain::Mysql do

  context ".start" do
    it "ping" do
      Mcrain[:mysql].start do |s|
        expect(s.client.query("show databases").map(&:values).flatten.sort).to eq ["information_schema", "mysql", "performance_schema"].sort
      end
    end

    context "with db_dir" do
      around do |example|
        Dir.mktmpdir do |dir|
          @tmp_db_dir = dir
          example.run
        end
      end
      let(:tmp_db_dir){ @tmp_db_dir }
      after { Mcrain[:mysql].db_dir = nil }

      let(:dbname){ "testdb1" }
      let(:tablename){ "testtable1" }
      let(:tabledata1){ "FOO" }

      it do
        old_cid = nil
        Mcrain[:mysql].db_dir = tmp_db_dir
        Mcrain[:mysql].start do |s|
          old_cid = s.container.id
          c0 = s.build_client
          c0.query("CREATE DATABASE #{dbname}")
          c0.select_db(dbname)
          c0.query("CREATE TABLE #{tablename} (id integer NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL);")
          c0.query("INSERT INTO #{tablename} (name) VALUES ('#{tabledata1}');")
        end
        Mcrain[:mysql].db_dir = tmp_db_dir
        Mcrain[:mysql].start do |s|
          expect(s.container.id).to_not eq old_cid
          c1 = s.build_client
          c1.select_db(dbname)
          expect(c1.query("SELECT NAME FROM #{tablename}").map(&:to_hash)).to eq [{"NAME"=> tabledata1}]
        end
      end
    end

  end

  context "start twice" do
    it do
      first = nil
      Mcrain[:mysql].start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain[:mysql].start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "skip_reset_after_teardown" do
    after{ Mcrain[:mysql].skip_reset_after_teardown = nil }

    it false do
      Mcrain[:mysql].skip_reset_after_teardown = false
      first_url = Mcrain[:mysql].url
      Mcrain[:mysql].start{ }
      expect(Mcrain[:mysql].url).to_not eq first_url
    end

    it true do
      Mcrain[:mysql].skip_reset_after_teardown = true
      first_url = Mcrain[:mysql].url
      Mcrain[:mysql].start{ }
      expect(Mcrain[:mysql].url).to eq first_url
    end
  end

end
