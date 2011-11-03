#!/usr/bin/env ruby

require 'optparse'

vol_ids = []
older_than = nil

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ec2-delete-old-snapshots.rb [-v vol-id] [-o older-than]"
  
  opts.on("-v", "--vol-id VOL_ID", "Volume ID(s) for which to delete old snapshots") do |vol_id|
    vol_ids << vol_id
  end
  
  opts.on("-o", "--older-than DAYS", "Delete snapshots older than x days") do |days|
    older_than = Time.now - (days.to_i * 24 * 60 * 60)
  end
end

parser.parse!

if vol_ids.empty? && older_than.nil?
  puts "Did not provide vol-id or older than"
  puts parser.banner
  exit
end

older_than ||= Time.now

vol_ids.each do |vol_id|
  puts "Will try to bulk delete for #{vol_id} older than #{older_than}"
end

credentials = {}
File.open(File.expand_path("~/.awssecret"), "r") do |f|
  credentials[:access_key_id] = f.readline.strip
  credentials[:secret_access_key] = f.readline.strip
end

require 'rubygems'
require 'right_aws'

ec2 = RightAws::Ec2.new(credentials[:access_key_id], credentials[:secret_access_key])

def delete_if_old(snapshot, older_than, ec2)
  start_time = Time.parse(snapshot[:aws_started_at])
  return unless start_time < older_than

  puts "DELETING! For volume: #{snapshot[:aws_volume_id]} snapshot: #{snapshot[:aws_id]} From: #{start_time}"
  ec2.delete_snapshot(snapshot[:aws_id])
end

snapshots_to_delete = {}
go_ahead_volumes = {}

ec2.describe_snapshots.each do |snapshot|
  vol_id = snapshot[:aws_volume_id].sub(/^vol-/, '')
  status = snapshot[:aws_status].to_sym
  start_time = Time.parse(snapshot[:aws_started_at])
  next unless vol_ids.include?(vol_id) && status == :completed

  snapshots_to_delete[vol_id] ||= []

  if go_ahead_volumes[vol_id]
    delete_if_old(snapshot, older_than, ec2)
  elsif start_time >= older_than
    puts "We have go ahead on deletion for volume #{vol_id}"
    go_ahead_volumes[vol_id] = true
    snapshots_to_delete[vol_id].each { |snap| delete_if_old(snap, older_than, ec2) }
  else
    snapshots_to_delete[vol_id] << snapshot
  end
end
