sub parse_filename_metadata
{
  my $file_location   = shift;
  my $doc_id          = shift;
  my $db_connection   = shift;
  my $collection_id   = shift;
  my $case_id         = shift;
# {{{

  my $parse_filename = read_profile_param('file_name_as_image_key',$collection_id,$db_connection);
  print "Parse_filename: $parse_filename docid: $doc_id\n";
  if($parse_filename == 1) {
    # Ignore the extension before applying the mask
    my ($file_basename,$file_path,$file_suffix) = fileparse($file_location, qr/\.[^.]*/);
 
    my $fw    = '%';  # Field wrapper
    my $db_fw = read_profile_param('fields_wrapper',$collection_id,$db_connection);
    my $file_format_regex = read_profile_param('file_format_regex',$collection_id,$db_connection);
 
    # tr won't take variables, as the transliteration table is normally built at compile time
    # so we use eval to get the values substituted at run time
    # but eval interprets every $ as a variable, so escape the first one
    eval "\$file_format_regex =~ tr/$db_fw/$fw/";
 
    # Read the fields from the string
    # First, build the regex
    # I'm replacing everything between percent signs with a *labeled* capture pattern
    # The (? specifies that it's a labeled pattern, the <$1> labels it with what we're
    # matching in first part of the s/// from the format string (i.e., the labels).
    # Then I just apply the regex, which populates the internal hash called %+ 
    # See the section on %+ on this page: http://perldoc.perl.org/perlvar.html for more info
    $file_format_regex  =~ s/$fw(.*?)$fw/(?<$1>.*?)/g;
    print "Constructed: $file_format_regex\n";
    # Now apply our labeled regex
    # Last $ is necessary so we don't match '' at the end
    $file_basename  =~ /$file_format_regex$/;
    # insert metadata with the results
    for my $field (keys(%+)) {
      my $tagflag = $+{$field};
      print "Inserting $field $tagflag}\n";
      metadata_insert($db_connection, $doc_id, lc($field), $tagflag);
      my $flag_id = get_flag_id($db_connection, $tagflag, $case_id);
      insert_doc_flag($db_connection, $doc_id, $flag_id);
      save_tag($doc_id, $tagflag, $loadfile);
    }
  }
# }}}
}
