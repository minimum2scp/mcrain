# coding: utf-8
require 'spec_helper'

require 'tmpdir'

describe Mcrain::Mysql do

  context ".start" do
    it "ping" do
      Mcrain::Mysql.new.start do |s|
        expect(s.client.query("show databases").map(&:values).flatten.sort).to eq ["information_schema", "mysql", "performance_schema"].sort
      end
    end

    context "with db_dir" do
      around do |example|
        Mcrain::DockerMachine.mktmpdir do |dir|
          @tmp_db_dir = dir
          example.run
        end
      end
      let(:tmp_db_dir){ @tmp_db_dir }

      let(:dbname){ "testdb1" }
      let(:tablename){ "testtable1" }
      let(:tabledata1){ "FOO" }

      it do
        old_cid = nil
        Mcrain::Mysql.new(db_dir: tmp_db_dir).start do |s|
          old_cid = s.container.id
          c0 = s.build_client
          c0.query("CREATE DATABASE #{dbname}")
          c0.select_db(dbname)
          c0.query("CREATE TABLE #{tablename} (id integer NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL);")
          c0.query("INSERT INTO #{tablename} (name) VALUES ('#{tabledata1}');")
        end
        Mcrain::Mysql.new(db_dir: tmp_db_dir).start do |s|
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
      Mcrain::Mysql.new.start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain::Mysql.new.start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "skip_reset_after_teardown" do
    it false do
      s = Mcrain::Mysql.new(skip_reset_after_teardown: false)
      first_url = s.url
      s.start{ }
      expect(s.url).to_not eq first_url
    end

    it true do
      s = Mcrain::Mysql.new(skip_reset_after_teardown: true)
      begin
        first_url = s.url
        s.start{ }
        expect(s.url).to eq first_url
      ensure
        s.reset
      end
    end
  end

end
