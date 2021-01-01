require 'mysql2'
require 'time'

client = Mysql2::Client.new(host: "localhost", username: "root", database: 'napkin')

client.query <<~QUERY
CREATE TABLE IF NOT EXISTS `table` (
	`id` BIGINT unsigned NOT NULL AUTO_INCREMENT,
	`updated_at` TIMESTAMP,
	KEY `index_table_id_updated_at` (`id`,`updated_at`) USING BTREE,
  KEY `index_table_updated_at` (`updated_at`) USING BTREE,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB;
QUERY

time = Time.parse("2020/12/30")

intended_records = 100_000_000
current_records = client.query("SELECT COUNT(*) FROM `table`").to_a.first.values.first
records_to_create = intended_records - current_records

batch_size = 2000
before = Time.now
i = 0

(1..records_to_create).each_slice(batch_size) do |offsets|
  per_sec = ((i * batch_size) / (Time.now - before)).round(0)
  puts "#{(((current_records + i * batch_size.to_f) / intended_records) * 100).round(2)}%, #{per_sec}/s"
  updated_ats = offsets.map { |offset| "(TIMESTAMPADD(SECOND, -#{offset}, '2020-12-30'))" }
  query = "INSERT INTO `table` (updated_at) VALUES#{updated_ats.join(",")}"
  client.query(query)

  i += 1
end

if records_to_create > 0
  taken = Time.now - before
  puts "Took #{taken}s, #{(records_to_create / taken).round(1)} records/sec"
else
  puts "#{current_records}/#{intended_records}"
end
