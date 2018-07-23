#!/apps/ruby/2.3.4/bin/ruby
#!/usr/bin/ruby
# processes records from the given file and outputs in Hathi format, like this:
# OCLC number(s) [tab] MMSID [tab] CH or WD [tab] BRT [tab][tab] issn [tab] 0 or 1
# The Marc records should look like this:
# 001 = MMSID
# 035 = OCLC number(s)
# 074 = GPO item number
# 086 = Gov Doc Classification Number
# 977c = LM = Lost /Missing
# 977d = Wdn = Withdrawn
# 977e = BRT = Brittle or damaged
# - SeanP
require 'marc'
require 'ruby-progressbar'
debug = false
if ARGV.empty?
  puts 'Usage: this.rb infile outfile'
  puts 'example: this.rb ccga.mrc ccga-hathi.mrc'
  exit
end

delim = " <TAB> "
infile = ARGV[0]
outfile = ARGV[1]

#set up files
reader = MARC::Reader.new(infile, :external_encoding => "UTF-8", :validate_encoding => true)
writer = File.open(outfile, "w")
errfname = 'out-corrupt.marc'
errfile = File.open(errfname, "w")

#set up counts
count = 1
errcount = 0

#config progress bar
progressbar = ProgressBar.create(:length => 40, :starting_at => 20, :total => nil)

#process records one at a time:
reader.each_raw do |raw|
  row = Hash.new
  skipOnError = false
  begin
    record = reader.decode(raw)
  rescue Exception => ex
    #record = MARC::Reader.decode(raw, :external_encoding => "UTF-8",:invalid => :replace)
    progressbar.log "An error occured, record #{count} may be corrupt, skipped and written to #{errfname}"
    skipOnError = true
    errcount += 1
  end
  if (debug)
    mmsid = record['001']
    progressbar.log "Record Number: #{count}, MMSID: #{mmsid}"
  end
  if skipOnError
    errfile.puts raw
  else #build the row for Hathi output file for this record

    #for mmsid
    row['mmsid'] = record['001'].value

    #For oclc numbers
    multioclc = false  #used if there are multiple oclc numbers
    record.each_by_tag("035") do |field|
      if field.is_a?(MARC::DataField)
        subfield = field['a']
        if debug
          progressbar.log "subfield: #{subfield}"
        end
        if subfield
          if multioclc
            row['oclc'] = row['oclc'] + "," + subfield #will be here if more than one oclc number
          else
            row['oclc'] = subfield #will be here for first oclc number
            multioclc = true
          end #if multioclc
        end #if subfield
      end #if field.is_a?
    end #record.each_by_tag

    #for govt doc
    row['gvt'] = "0"
    if record['074'] or record['086']
      row['gvt'] = "1"
    end #if record

    #for CH, WD, or LM
    row['loc'] = ""
    if record['977']['d'].to_s.downcase.include? "wdn"
      row['loc'] = "WD"
    elsif record['977']['d']
      row['loc'] = "CH"
    end
    if record['977']['c'].to_s.downcase.include? "lm"
      row['loc'] = "LM"
    end

    #for britle
    row['condition'] = ""
    if record['977']['b'].to_s.downcase.include? "brt"
      row['condition'] = "BRT"
    end

    #for Chronology (only for multi part monos)
    row['chron'] = ""
    if record['977']['b']
      row['chron'] = record['977']['b']
    end

    begin
      #write the row to the file
      writer.puts row['oclc'] + delim + row['mmsid'] + delim + row['loc'] + delim + row['condition'] + delim + row['chron'] +  delim + delim + row['gvt']
    rescue Exception => ex
      progressbar.log "An error occured at record #{count}.  Error: #{ex.message}"
    end
  end
  progressbar.increment if count % 1000 == 0
  count += 1
end #reader loop

progressbar.log "#{count-1} records processed, #{errcount} of which were corrupt. "
progressbar.finish

writer.close
#reader.close
errfile.close
