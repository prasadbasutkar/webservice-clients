#!/usr/bin/env perl

=head1 NAME

hmmer3_phmmer.pl

=head1 DESCRIPTION

HMMER 3 phmmer (REST) web service Perl client using L<LWP>.

Tested with:

=over

=item *
L<LWP> 6.35, L<XML::Simple> 2.25 and Perl 5.22.0 (MacOS 10.13.6)

=back

For further information see:

=over

=item *
L<https://www.ebi.ac.uk/Tools/webservices/>

=back

=head1 LICENSE

Copyright 2012-2018 EMBL - European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Perl Client Automatically generated with:
https://github.com/ebi-wp/webservice-clients-generator

=cut

# ======================================================================
# Enable Perl warnings
use strict;
use warnings;

# Load libraries
use English;
use LWP;
use XML::Simple;
use Getopt::Long qw(:config no_ignore_case bundling);
use File::Basename;
use Data::Dumper;
use Time::HiRes qw(usleep);
use JSON::XS;
use Try::Tiny;

# Base URL for service
my $baseUrl = 'https://www.ebi.ac.uk/Tools/services/rest/hmmer3_phmmer';

# Set interval for checking status
my $checkInterval = 3;

# Set maximum number of 'ERROR' status calls to call job failed.
my $maxErrorStatusCount = 3;

# Output level
my $outputLevel = 1;

# Process command-line options
my $numOpts = scalar(@ARGV);
my %params = (
    'debugLevel' => 0,
    'maxJobs'    => 1
);

# Default parameter values (should get these from the service)
GetOptions(
    # Tool specific options
    'incE=s'          => \$params{'incE'},           # Significance E-values[Sequence]
    'incdomE=s'       => \$params{'incdomE'},        # Significance E-values[Hit]
    'E=s'             => \$params{'E'},              # Report E-values[Sequence]
    'domE=s'          => \$params{'domE'},           # Report E-values[Hit]
    'incT=s'          => \$params{'incT'},           # Significance bit scores[Sequence]
    'incdomT=s'       => \$params{'incdomT'},        # Significance bit scores[Hit]
    'T=s'             => \$params{'T'},              # Report bit scores[Sequence]
    'domT=s'          => \$params{'domT'},           # Report bit scores[Hit]
    'popen=s'         => \$params{'popen'},          # Gap Penalties[open]
    'pextend=s'       => \$params{'pextend'},        # Gap Penalties[extend]
    'mx=s'            => \$params{'mx'},             # Gap Penalties[Substitution scoring matrix]
    'nobias'          => \$params{'nobias'},         # Filters
    'alignView'       => \$params{'alignView'},      # Output alignment in result
    'database=s'      => \$params{'database'},       # Sequence Database
    'evalue=f'        => \$params{'evalue'},         # Expectation value cut-off for reporting target profiles in the per-target output.
    'sequence=s'      => \$params{'sequence'},       # The input sequence can be entered directly into this form. The sequence can be be in FASTA or UniProtKB/Swiss-Prot format. A partially formatted sequence is not accepted. Adding a return to the end of the sequence may help certain applications understand the input. Note that directly using data from word processors may yield unpredictable results as hidden/control characters may be present.
    # Generic options
    'email=s'         => \$params{'email'},          # User e-mail address
    'title=s'         => \$params{'title'},          # Job title
    'outfile=s'       => \$params{'outfile'},        # Output file name
    'outformat=s'     => \$params{'outformat'},      # Output file type
    'jobid=s'         => \$params{'jobid'},          # JobId
    'help|h'          => \$params{'help'},           # Usage help
    'async'           => \$params{'async'},          # Asynchronous submission
    'polljob'         => \$params{'polljob'},        # Get results
    'pollFreq=f'      => \$params{'pollFreq'},       # Poll Frequency
    'resultTypes'     => \$params{'resultTypes'},    # Get result types
    'status'          => \$params{'status'},         # Get status
    'params'          => \$params{'params'},         # List input parameters
    'paramDetail=s'   => \$params{'paramDetail'},    # Get details for parameter
    'acc=i'           => \$params{'acc'},             # Get accession ID, how many from top
    'multifasta'      => \$params{'multifasta'},     # Multiple fasta input
    'useSeqId'        => \$params{'useSeqId'},       # Seq Id file name
    'maxJobs=i'       => \$params{'maxJobs'},        # Max. parallel jobs

    'verbose'         => \$params{'verbose'},        # Increase output level
    'quiet'           => \$params{'quiet'},          # Decrease output level
    'debugLevel=i'    => \$params{'debugLevel'},     # Debugging level
    'baseUrl=s'       => \$baseUrl,                  # Base URL for service.
);
if ($params{'verbose'}) {$outputLevel++}
if ($params{'quiet'}) {$outputLevel--}
if ($params{'pollFreq'}) {$checkInterval = $params{'pollFreq'} * 1000 * 1000}
if ($params{'baseUrl'}) {$baseUrl = $params{'baseUrl'}}

# Debug mode: LWP version
&print_debug_message('MAIN', 'LWP::VERSION: ' . $LWP::VERSION,
    1);

# Debug mode: print the input parameters
&print_debug_message('MAIN', "params:\n" . Dumper(\%params), 11);

# LWP UserAgent for making HTTP calls (initialised when required).
my $ua;

# Get the script filename for use in usage messages
my $scriptName = basename($0, ());

# Print usage and exit if requested
if ($params{'help'} || $numOpts == 0) {
    &usage();
    exit(0);
}

# Debug mode: show the base URL
&print_debug_message('MAIN', 'baseUrl: ' . $baseUrl, 1);
if (
    !(
        $params{'polljob'}
            || $params{'resultTypes'}
            || $params{'status'}
            || $params{'params'}
            || $params{'paramDetail'}
    )
        && !(defined($ARGV[0]) || defined($params{'sequence'}))
) {

    # Bad argument combination, so print error message and usage
    print STDERR 'Error: bad option combination', "\n";
    &usage();
    exit(1);
}
# Get parameters list
elsif ($params{'params'}) {
    &print_tool_params();
}

# Get parameter details
elsif ($params{'paramDetail'}) {
    &print_param_details($params{'paramDetail'});
}

# Job status
elsif ($params{'status'} && defined($params{'jobid'})) {
    &print_job_status($params{'jobid'});
}

# Result types
elsif ($params{'resultTypes'} && defined($params{'jobid'})) {
    &print_result_types($params{'jobid'});
}

# Poll job and get results
elsif ($params{'polljob'} && defined($params{'jobid'})) {
    &get_results($params{'jobid'});
}

# Submit a job
else {
    # Multiple input sequence mode, assume fasta format.
    if (defined($params{'multifasta'}) && $params{'multifasta'}) {
        &multi_submit_job();
    }

    # Entry identifier list file.
    elsif ((defined($params{'sequence'}) && $params{'sequence'} =~ m/^\@/)
        || (defined($ARGV[0]) && $ARGV[0] =~ m/^\@/)) {
        my $list_filename = $params{'sequence'} || $ARGV[0];
        $list_filename =~ s/^\@//;
        &list_file_submit_job($list_filename);
    }
    # Default: single sequence/identifier.
    else {
        # Warn for invalid batch only option use.
        if (defined($params{'useSeqId'}) && $params{'useSeqId'}) {
            print STDERR "Warning: --useSeqId option ignored.\n";
            delete $params{'useSeqId'};
        }
        if (defined($params{'maxJobs'}) && $params{'maxJobs'} > 1) {
            print STDERR "Warning: --maxJobs option ignored.\n";
            $params{'maxJobs'} = 1;
        }
        # Load the sequence data and submit.
        &submit_job(&load_data());
    }
}


# Seq db index
my $db_index = '2'; # default uniprotkb

=head1 FUNCTIONS

=cut

### Wrappers for REST resources ###

=head2 rest_user_agent()

Get a LWP UserAgent to use to perform REST requests.

  my $ua = &rest_user_agent();

=cut

sub rest_user_agent() {
    print_debug_message('rest_user_agent', 'Begin', 21);
    # Create an LWP UserAgent for making HTTP calls.
    my $ua = LWP::UserAgent->new();
    # Set 'User-Agent' HTTP header to identifiy the client.
    my $revisionNumber = 0;
    $revisionNumber = $1 if ('$Revision$' =~ m/(\d+)/);
    $ua->agent("EBI-Sample-Client/$revisionNumber ($scriptName; $OSNAME) " . $ua->agent());
    # Configure HTTP proxy support from environment.
    $ua->env_proxy;
    print_debug_message('rest_user_agent', 'End', 21);
    return $ua;
}

=head2 rest_error()

Check a REST response for an error condition. An error is mapped to a die.

  &rest_error($response, $content_data);

=cut

sub rest_error() {
    print_debug_message('rest_error', 'Begin', 21);
    my $response = shift;
    my $contentdata;
    if (scalar(@_) > 0) {
        $contentdata = shift;
    }
    if (!defined($contentdata) || $contentdata eq '') {
        $contentdata = $response->content();
    }
    # Check for HTTP error codes
    if ($response->is_error) {
        my $error_message = '';
        # HTML response.
        if ($contentdata =~ m/<h1>([^<]+)<\/h1>/) {
            $error_message = $1;
        }
        #  XML response.
        elsif ($contentdata =~ m/<description>([^<]+)<\/description>/) {
            $error_message = $1;
        }
        die $error_message;
    }
    print_debug_message('rest_error', 'End', 21);
}

=head2 rest_request()

Perform a REST request (HTTP GET).

  my $response_str = &rest_request($url);

=cut

sub rest_request {
    print_debug_message('rest_request', 'Begin', 11);
    my $requestUrl = shift;
    print_debug_message('rest_request', 'URL: ' . $requestUrl, 11);

    # Get an LWP UserAgent.
    $ua = &rest_user_agent() unless defined($ua);
    # Available HTTP compression methods.
    my $can_accept;
    eval {
        $can_accept = HTTP::Message::decodable();
    };
    $can_accept = '' unless defined($can_accept);
    # Perform the request
    my $response = $ua->get($requestUrl,
        'Accept-Encoding' => $can_accept, # HTTP compression.
    );
    print_debug_message('rest_request', 'HTTP status: ' . $response->code,
        11);
    print_debug_message('rest_request',
        'response length: ' . length($response->content()), 11);
    print_debug_message('rest_request',
        'request:' . "\n" . $response->request()->as_string(), 32);
    print_debug_message('rest_request',
        'response: ' . "\n" . $response->as_string(), 32);
    # Unpack possibly compressed response.
    my $retVal;
    if (defined($can_accept) && $can_accept ne '') {
        $retVal = $response->decoded_content();
    }
    # If unable to decode use orginal content.
    $retVal = $response->content() unless defined($retVal);
    # Check for an error.
    &rest_error($response, $retVal);
    print_debug_message('rest_request', 'retVal: ' . $retVal, 12);
    print_debug_message('rest_request', 'End', 11);

    # Return the response data
    return $retVal;
}
=head2 rest_request_for_accid()

Perform a REST request (HTTP GET).

  my $response_str = &rest_request($url);

=cut

sub rest_request_for_accid {
    print_debug_message('rest_request_for_accid', 'Begin', 11);
    my $requestUrl = shift;
    print_debug_message('rest_request_for_accid', 'URL: ' . $requestUrl, 11);

    # Get an LWP UserAgent.
    $ua = &rest_user_agent() unless defined($ua);
    # Available HTTP compression methods.
    my $can_accept;
    eval {
        $can_accept = HTTP::Message::decodable();
    };
    $can_accept = '' unless defined($can_accept);
    # Perform the request
    my $response = $ua->get($requestUrl,
        'Accept-Encoding' => $can_accept, # HTTP compression.
    );

    # Unpack possibly compressed response.
    my $retVal;
    if (defined($can_accept) && $can_accept ne '') {
        $retVal = $response->decoded_content();
    }
    # If unable to decode use orginal content.
    $retVal = $response->content() unless defined($retVal);
    # Check for an error.
    &rest_error($response, $retVal);
    print_debug_message('rest_request', 'End', 11);

    my @lines = split /\n/, $retVal;

    my $v_cnt = 0;
    my $top_acc = 20;
    if (defined $params{'acc'}) {
        $top_acc = $params{'acc'};
    }

    my $new_id_len = 0;
    foreach my $line (@lines) {

        # Updating HMMER numeric ID to Accession
        if ($v_cnt >= $top_acc) {
            last;
        }

        my $where_id_begin = index($line, '>>');

        if ($where_id_begin > -1) {
            $v_cnt++;

            my $grab_id = substr($line, $where_id_begin + 3, 30);
            $grab_id =~ s/\s*$//; # trim left whitespace

            try {

                my $acc_id = rest_get_accid($grab_id);
				print_debug_message('rest_request_for_accid', '###>>>>>>>> grab_id: ' . $grab_id, 42);
				print_debug_message('rest_request_for_accid', '###>>>>>>>> acc_id: ' . $acc_id, 42);
                if ($grab_id and $acc_id) {

					# List, Header, Details

					my $isChEMBL = substr($acc_id,0,2);
					my $new_id =$acc_id;

					# List & Details
                    #my $old_id_forDetail = '  ' . $grab_id . ' ';
                    #my $new_id_forDetail = '' . substr($new_id . '  ', 0, length($old_id_forDetail));
                    my $old_id_forDetail = LPad($grab_id, ' ', 10);
                    my $new_id_forDetail = LPad($new_id, ' ', length($old_id_forDetail)-length($new_id));

					print_debug_message('rest_request_for_accid', '###>>>>>>>> old_id_forDetail=' . $old_id_forDetail . '==' , 42);
					print_debug_message('rest_request_for_accid', '###>>>>>>>> new_id_forDetail=' . $new_id_forDetail . '==' , 42);

					#1  Details =Sequence list (Start with two spaces) &
                    $retVal =~ s/$old_id_forDetail/$new_id_forDetail/g;


					#2 >> Sequence ID (Start with '>>' and One spaces)
                    my $old_id_forDetailHeader = '>> ' . $grab_id;
                    my $new_id_forDetailHeader = '>> ' . $acc_id;                      # both spaces requries to avoid unexpected replacement
					$retVal =~ s/$old_id_forDetailHeader/$new_id_forDetailHeader/g;


					# List (Start with two spaces)
                    #my $old_id_forList = '   ' . $grab_id . '';
                    #my $new_id_forList = '' . $new_id . '   ';

                    my $old_id_forList = LPad($grab_id , ' ', 2) . ' ';
                    my $new_id_forList = LPad($new_id , ' ', 2) . ' ';
					print_debug_message('rest_request_for_accid', '###>>>>>>>> old_id_forList=' . $old_id_forList . '==' , 42);
					print_debug_message('rest_request_for_accid', '###>>>>>>>> new_id_forList=' . $new_id_forList . '==' , 42);
					$retVal =~ s/$old_id_forList/$new_id_forList/g;


					# >> Sequence ID (Start with '>>' and One spaces)

					# List (Except not start with 00) & Details
                    my $HMMERID_StartWithZero = sprintf("%09d", $grab_id) . ' ';
                    my $new_HMMERID_StartWithZero = LPad($new_id, ' ', length($HMMERID_StartWithZero)-length($new_id));

					print_debug_message('rest_request_for_accid', '###>>>>>>>> HMMERID_StartWithZero       =' . $HMMERID_StartWithZero . '==' , 42);
					print_debug_message('rest_request_for_accid', '###>>>>>>>> new_HMMERID_StartWithZero   =' . $new_HMMERID_StartWithZero . '==' , 42);
                    $retVal =~ s/$HMMERID_StartWithZero/$new_HMMERID_StartWithZero/g;
                }
            }
            catch {
                #warn "Caught Getting Accession error: $_";
                warn " Not found the Accession for: " . $grab_id;
                #last;
            }
        }

    }

    # Return the response data
    return $retVal;
}

sub LPad {
    my ($str, $padding, $length) = @_;

    my $pad_length = $length;
    $pad_length = 0 if $pad_length < 0;
    $padding x= $pad_length;
    $padding.$str;
}

sub RPad {
    my ($str, $padding, $length) = @_;

    my $pad_length = $length - length $str;
    $pad_length = 0 if $pad_length < 0;
    $padding x= $pad_length;
    $str.$padding;
}

=head2 rest_get_accid()

Retrive acc with entry id.
http://www.ebi.ac.uk/ebisearch/ws/rest/hmmer_seq/entry/14094/xref/uniprot
http://www.ebi.ac.uk/ebisearch/ws/rest/hmmer_seq/entry/14094?fields=id,content

=cut

sub rest_get_accid {
    print_debug_message('rest_get_accid', '################ Begin', 42);
    #my (@reference);
    my $each_acc_id;
    my ($entryid) = @_;

    my $domainid = 'hmmer_seq';
    my $ebisearch_baseUrl = 'http://www.ebi.ac.uk/ebisearch/ws/rest/';

    my $url = $ebisearch_baseUrl . $domainid . "/entry/" . $entryid . "?fields=id,content";
    my $reference_list_xml_str = &rest_request($url);
    my $reference_list_xml = XMLin($reference_list_xml_str);

    # read XML file
    my $data = XMLin($reference_list_xml_str);
    my $acc_info = $data->{'entries'}->{'entry'}->{'fields'}->{'field'}->{'content'}->{'values'}->{'value'};

    if ($acc_info) {

        my $decoded;

        try {
            $decoded = JSON::XS::decode_json($acc_info);
        }
        catch {
            warn "Caught JSON::XS decode error: $_";
			print_debug_message('rest_get_accid', '### catch ###' , 42);
        };

        my @dbs1 = $decoded->{'db'};
        my @selected_db = $dbs1[0]->[$db_index];

        $each_acc_id = $selected_db[0]->[0]->{'dn'};

    }
    else {
        print_debug_message('rest_get_accid', '=acc_info NONE: ', 42);
    }

    print_debug_message('rest_get_accid', 'End', 42);
	print_debug_message('rest_get_accid', '###>>>>>>>> each_acc_id: ' . $each_acc_id, 42);
    return($each_acc_id);
}

=head2 rest_get_parameters()

Get list of tool parameter names.

  my (@param_list) = &rest_get_parameters();

=cut

sub rest_get_parameters {
    print_debug_message('rest_get_parameters', 'Begin', 1);
    my $url = $baseUrl . '/parameters/';
    my $param_list_xml_str = rest_request($url);
    my $param_list_xml = XMLin($param_list_xml_str);
    my (@param_list) = @{$param_list_xml->{'id'}};
    print_debug_message('rest_get_parameters', 'End', 1);
    return(@param_list);
}

=head2 rest_get_parameter_details()

Get details of a tool parameter.

  my $paramDetail = &rest_get_parameter_details($param_name);

=cut

sub rest_get_parameter_details {
    print_debug_message('rest_get_parameter_details', 'Begin', 1);
    my $parameterId = shift;
    print_debug_message('rest_get_parameter_details',
        'parameterId: ' . $parameterId, 1);
    my $url = $baseUrl . '/parameterdetails/' . $parameterId;
    my $param_detail_xml_str = rest_request($url);
    my $param_detail_xml = XMLin($param_detail_xml_str);
    print_debug_message('rest_get_parameter_details', 'End', 1);
    return($param_detail_xml);
}

=head2 rest_run()

Submit a job.

  my $job_id = &rest_run($email, $title, \%params );

=cut

sub rest_run {
    print_debug_message('rest_run', 'Begin', 1);
    my $email = shift;
    my $title = shift;
    my $params = shift;
    $email = '' if (!$email);
    print_debug_message('rest_run', 'email: ' . $email, 1);
    if (defined($title)) {
        print_debug_message('rest_run', 'title: ' . $title, 1);
    }
    print_debug_message('rest_run', 'params: ' . Dumper($params), 1);

    # Get an LWP UserAgent.
    $ua = &rest_user_agent() unless defined($ua);

    # Clean up parameters
    my (%tmp_params) = %{$params};
    $tmp_params{'email'} = $email;
    $tmp_params{'title'} = $title;
    foreach my $param_name (keys(%tmp_params)) {
        if (!defined($tmp_params{$param_name})) {
            delete $tmp_params{$param_name};
        }
    }

    # Submit the job as a POST
    my $url = $baseUrl . '/run';
    my $response = $ua->post($url, \%tmp_params);
    print_debug_message('rest_run', 'HTTP status: ' . $response->code, 11);
    print_debug_message('rest_run',
        'request:' . "\n" . $response->request()->as_string(), 11);
    print_debug_message('rest_run',
        'response: ' . length($response->as_string()) . "\n" . $response->as_string(), 11);

    # Check for an error.
    &rest_error($response);

    # The job id is returned
    my $job_id = $response->content();
    print_debug_message('rest_run', 'End', 1);
    return $job_id;
}

=head2 rest_get_status()

Check the status of a job.

  my $status = &rest_get_status($job_id);

=cut

sub rest_get_status {
    print_debug_message('rest_get_status', 'Begin', 1);
    my $job_id = shift;
    print_debug_message('rest_get_status', 'jobid: ' . $job_id, 2);
    my $status_str = 'UNKNOWN';
    my $url = $baseUrl . '/status/' . $job_id;
    $status_str = &rest_request($url);
    print_debug_message('rest_get_status', 'status_str: ' . $status_str, 2);
    print_debug_message('rest_get_status', 'End', 1);
    return $status_str;
}

=head2 rest_get_result_types()

Get list of result types for finished job.

  my (@result_types) = &rest_get_result_types($job_id);

=cut

sub rest_get_result_types {
    print_debug_message('rest_get_result_types', 'Begin', 1);
    my $job_id = shift;
    print_debug_message('rest_get_result_types', 'jobid: ' . $job_id, 2);
    my (@resultTypes);
    my $url = $baseUrl . '/resulttypes/' . $job_id;
    my $result_type_list_xml_str = &rest_request($url);
    my $result_type_list_xml = XMLin($result_type_list_xml_str);
    (@resultTypes) = @{$result_type_list_xml->{'type'}};
    print_debug_message('rest_get_result_types',
        scalar(@resultTypes) . ' result types', 2);
    print_debug_message('rest_get_result_types', 'End', 1);
    return(@resultTypes);
}

=head2 rest_get_result()

Get result data of a specified type for a finished job.

  my $result = rest_get_result($job_id, $result_type);

=cut

sub rest_get_result {
    print_debug_message('rest_get_result', 'Begin', 1);
    my $job_id = shift;
    my $type = shift;
    print_debug_message('rest_get_result', 'jobid: ' . $job_id, 1);
    print_debug_message('rest_get_result', 'type: ' . $type, 1);
    my $url = $baseUrl . '/result/' . $job_id . '/' . $type;
    my $result = &rest_request_for_accid($url);

    print_debug_message('rest_get_result', length($result) . ' characters',
        1);
    print_debug_message('rest_get_result', 'End', 1);
    return $result;
}

### Service actions and utility functions ###

=head2 print_debug_message()

Print debug message at specified debug level.

  &print_debug_message($method_name, $message, $level);

=cut

sub print_debug_message {
    my $function_name = shift;
    my $message = shift;
    my $level = shift;
    if ($level <= $params{'debugLevel'}) {
        print STDERR '[', $function_name, '()] ', $message, "\n";
    }
}

=head2 print_tool_params()

Print list of tool parameters.

  &print_tool_params();

=cut

sub print_tool_params {
    print_debug_message('print_tool_params', 'Begin', 1);
    my (@param_list) = &rest_get_parameters();
    foreach my $param (sort (@param_list)) {
        print $param, "\n";
    }
    print_debug_message('print_tool_params', 'End', 1);
}

=head2 print_param_details()

Print details of a tool parameter.

  &print_param_details($param_name);

=cut

sub print_param_details {
    print_debug_message('print_param_details', 'Begin', 1);
    my $paramName = shift;
    print_debug_message('print_param_details', 'paramName: ' . $paramName, 2);
    my $paramDetail = &rest_get_parameter_details($paramName);
    print $paramDetail->{'name'}, "\t", $paramDetail->{'type'}, "\n";
    print $paramDetail->{'description'}, "\n";
    if (defined($paramDetail->{'values'}->{'value'})) {
        if (ref($paramDetail->{'values'}->{'value'}) eq 'ARRAY') {
            foreach my $value (@{$paramDetail->{'values'}->{'value'}}) {
                &print_param_value($value);
            }
        }
        else {
            &print_param_value($paramDetail->{'values'}->{'value'});
        }
    }
    print_debug_message('print_param_details', 'End', 1);
}

=head2 print_param_value()

Print details of a tool parameter value.

  &print_param_details($param_value);

Used by print_param_details() to handle both singluar and array values.

=cut

sub print_param_value {
    my $value = shift;
    print $value->{'value'};
    if ($value->{'defaultValue'} eq 'true') {
        print "\t", 'default';
    }
    print "\n";
    print "\t", $value->{'label'}, "\n";
    if (defined($value->{'properties'})) {
        foreach
        my $key (sort ( keys(%{$value->{'properties'}{'property'}}) )) {
            if (ref($value->{'properties'}{'property'}{$key}) eq 'HASH'
                && defined($value->{'properties'}{'property'}{$key}{'value'})
            ) {
                print "\t", $key, "\t",
                    $value->{'properties'}{'property'}{$key}{'value'}, "\n";
            }
            else {
                print "\t", $value->{'properties'}{'property'}{'key'},
                    "\t", $value->{'properties'}{'property'}{'value'}, "\n";
                last;
            }
        }
    }
}

=head2 print_job_status()

Print status of a job.

  &print_job_status($job_id);

=cut

sub print_job_status {
    print_debug_message('print_job_status', 'Begin', 1);
    my $jobid = shift;
    print_debug_message('print_job_status', 'jobid: ' . $jobid, 1);
    if ($outputLevel > 0) {
        print STDERR 'Getting status for job ', $jobid, "\n";
    }
    my $result = &rest_get_status($jobid);
    print "$result\n";
    if ($result eq 'FINISHED' && $outputLevel > 0) {
        print STDERR "To get results: perl $scriptName --polljob --jobid " . $jobid
            . "\n";
    }
    print_debug_message('print_job_status', 'End', 1);
}

=head2 print_result_types()

Print available result types for a job.

  &print_result_types($job_id);

=cut

sub print_result_types {
    print_debug_message('result_types', 'Begin', 1);
    my $jobid = shift;
    print_debug_message('result_types', 'jobid: ' . $jobid, 1);
    if ($outputLevel > 0) {
        print STDERR 'Getting result types for job ', $jobid, "\n";
    }
    my $status = &rest_get_status($jobid);
    if ($status eq 'PENDING' || $status eq 'RUNNING') {
        print STDERR 'Error: Job status is ', $status,
            '. To get result types the job must be finished.', "\n";
    }
    else {
        my (@resultTypes) = &rest_get_result_types($jobid);
        if ($outputLevel > 0) {
            print STDOUT 'Available result types:', "\n";
        }
        foreach my $resultType (@resultTypes) {
            print STDOUT $resultType->{'identifier'}, "\n";
            if (defined($resultType->{'label'})) {
                print STDOUT "\t", $resultType->{'label'}, "\n";
            }
            if (defined($resultType->{'description'})) {
                print STDOUT "\t", $resultType->{'description'}, "\n";
            }
            if (defined($resultType->{'mediaType'})) {
                print STDOUT "\t", $resultType->{'mediaType'}, "\n";
            }
            if (defined($resultType->{'fileSuffix'})) {
                print STDOUT "\t", $resultType->{'fileSuffix'}, "\n";
            }
        }
        if ($status eq 'FINISHED' && $outputLevel > 0) {
            print STDERR "\n", 'To get results:', "\n",
                "  perl $scriptName --polljob --jobid " . $params{'jobid'} . "\n",
                "  perl $scriptName --polljob --outformat <type> --jobid "
                    . $params{'jobid'} . "\n";
        }
    }
    print_debug_message('result_types', 'End', 1);
}

=head2 submit_job()

Submit a job to the service.

  &submit_job($seq);

=cut

sub submit_job {
    print_debug_message('submit_job', 'Begin', 1);

    # Set input sequence
    $params{'sequence'} = shift;
    my $seq_id = shift;

    # Set input seqdb ; ensemblgenomes,uniprotkb,uniprotrefprot,rp15,rp35,rp55,rp75,ensembl,merops,qfo,swissprot,pdb,meropsscan
    my $param_seqdb = $params{'database'};

    if ($param_seqdb eq 'ensemblgenomes') {
        $db_index = "1";
    }
    if ($param_seqdb eq 'uniprotkb') {
        $db_index = "2";
    }
    if ($param_seqdb eq 'rp75') {
        $db_index = "3";
    }
    if ($param_seqdb eq 'uniprotrefprot') {
        $db_index = "4";
    }
    if ($param_seqdb eq 'rp55') {
        $db_index = "5";
    }
    if ($param_seqdb eq 'rp35') {
        $db_index = "6";
    }
    if ($param_seqdb eq 'rp15') {
        $db_index = "7";
    }
    if ($param_seqdb eq 'ensembl') {
        $db_index = "8";
    }
    if ($param_seqdb eq 'merops') {
        $db_index = "9";
    }
    if ($param_seqdb eq 'qfo') {
        $db_index = "10";
    }
    if ($param_seqdb eq 'swissprot') {
        $db_index = "11";
    }
    if ($param_seqdb eq 'pdb') {
        $db_index = "12";
    }
    if ($param_seqdb eq 'chembl') {
        $db_index = "13";
    }
    if ($param_seqdb eq 'meropsscan') {
        $db_index = "14";
    }

    # Load parameters
    &load_params();

    # Submit the job
    my $jobid = &rest_run($params{'email'}, $params{'title'}, \%params);

    # Asynchronous submission.
    if (defined($params{'async'})) {
        print STDOUT $jobid, "\n";
        if ($outputLevel > 0) {
            print STDERR
                "To check status: perl $scriptName --status --jobid $jobid\n";
        }
    }

    # Simulate synchronous submission serial mode.
    else {
        if ($outputLevel > 0) {
            print STDERR "JobId: $jobid\n";
        } else {
            print STDERR "$jobid\n";
        }
        usleep($checkInterval);
        # Get results.
        &get_results($jobid, $seq_id);

    }
    print_debug_message('submit_job', 'End', 1);
    return $jobid;
}
=head2 multi_submit_job()

Submit multiple jobs assuming input is a collection of fasta formatted sequences.

  &multi_submit_job();

=cut

sub multi_submit_job {
    print_debug_message('multi_submit_job', 'Begin', 1);
    my (@filename_list) = ();

    # Query sequence
    if (defined($ARGV[0])) {                  # Bare option
        if (-f $ARGV[0] || $ARGV[0] eq '-') { # File
            push(@filename_list, $ARGV[0]);
        }
        else {
            warn 'Warning: Input file "' . $ARGV[0] . '" does not exist';
        }
    }
    if ($params{'sequence'}) {                                      # Via --sequence
        if (-f $params{'sequence'} || $params{'sequence'} eq '-') { # File
            push(@filename_list, $params{'sequence'});
        }
        else {
            warn 'Warning: Input file "'
                . $params{'sequence'}
                . '" does not exist';
        }
    }

    # Job identifier tracking for parallel execution.
    my @jobid_list = ();
    my $job_number = 0;
    $/ = '>';
    foreach my $filename (@filename_list) {
        my $INFILE;
        if ($filename eq '-') { # STDIN.
            open($INFILE, '<-')
                or die 'Error: unable to STDIN (' . $! . ')';
        }
        else { # File.
            open($INFILE, '<', $filename)
                or die 'Error: unable to open file '
                . $filename . ' ('
                . $! . ')';
        }
        while (<$INFILE>) {
            my $seq = $_;
            $seq =~ s/>$//;
            if ($seq =~ m/(\S+)/) {
                my $seq_id = $1;
                print STDERR "Submitting job for: $seq_id\n"
                    if ($outputLevel > 0);
                $seq = '>' . $seq;
                &print_debug_message('multi_submit_job', $seq, 11);
                $job_number++;
                my $job_id = &submit_job($seq, $seq_id);

                my $job_info_str = sprintf('%s %d %d', $job_id, 0, $job_number);

                push(@jobid_list, $job_info_str);
            }

            # Parallel mode, wait for job(s) to finish to free slots.
            while ($params{'maxJobs'} > 1
                && scalar(@jobid_list) >= $params{'maxJobs'}) {
                &_job_list_poll(\@jobid_list);
                print_debug_message('multi_submit_job',
                    'Remaining jobs: ' . scalar(@jobid_list), 1);
            }
        }
        close $INFILE;
    }

    # Parallel mode, wait for remaining jobs to finish.
    while ($params{'maxJobs'} > 1 && scalar(@jobid_list) > 0) {
        &_job_list_poll(\@jobid_list);
        print_debug_message('multi_submit_job',
            'Remaining jobs: ' . scalar(@jobid_list), 1);
    }
    print_debug_message('multi_submit_job', 'End', 1);
}


=head2 _job_list_poll()

Poll the status of a list of jobs and fetch results for finished jobs.

  while(scalar(@jobid_list) > 0) {
    &_job_list_poll(\@jobid_list);
  }

=cut

sub _job_list_poll {
    print_debug_message('_job_list_poll', 'Begin', 1);
    my $jobid_list = shift;
    print_debug_message('_job_list_poll', 'Num jobs: ' . scalar(@$jobid_list),
        11);

    # Loop though job Id list polling job status.
    for (my $jobNum = (scalar(@$jobid_list) - 1); $jobNum > -1; $jobNum--) {
        my ($jobid, $seq_id, $error_count, $job_number) =
            split(/\s+/, $jobid_list->[$jobNum]);
        print_debug_message('_job_list_poll', 'jobNum: ' . $jobNum, 12);
        print_debug_message('_job_list_poll',
            'Job info: ' . $jobid_list->[$jobNum], 12);

        # Get job status.
        my $job_status = &rest_get_status($jobid);
        print_debug_message('_job_list_poll', 'Status: ' . $job_status, 12);

        # Fetch results and remove finished/failed jobs from list.
        if (
            !(
                $job_status eq 'RUNNING'
                    || $job_status eq 'PENDING'
                    || ($job_status eq 'ERROR'
                    && $error_count < $maxErrorStatusCount)
            )
        ) {
            if ($job_status eq 'ERROR' || $job_status eq 'FAILED') {
                print STDERR
                    "Warning: job $jobid failed for sequence $job_number: $seq_id\n";
            }
            &get_results($jobid, $seq_id);
            splice(@$jobid_list, $jobNum, 1);
        }
        else {

            # Update error count, increment for new error or clear old errors.
            if ($job_status eq 'ERROR') {
                $error_count++;
            }
            elsif ($error_count > 0) {
                $error_count--;
            }

            # Update job tracking info.
            my $job_info_str = sprintf('%s %s %d %d',
                $jobid, $seq_id, $error_count, $job_number);
            $jobid_list->[$jobNum] = $job_info_str;
        }
    }
    print_debug_message('_job_list_poll', 'Num jobs: ' . scalar(@$jobid_list),
        11);
    print_debug_message('_job_list_poll', 'End', 1);
}

=head2 list_file_submit_job()

Submit multiple jobs using a file containing a list of entry identifiers as
input.

  &list_file_submit_job($list_filename)

=cut

sub list_file_submit_job {
    print_debug_message('list_file_submit_job', 'Begin', 1);
    my $filename = shift;

    # Open the file of identifiers.
    my $LISTFILE;
    if ($filename eq '-') { # STDIN.
        open($LISTFILE, '<-')
            or die 'Error: unable to STDIN (' . $! . ')';
    }
    else { # File.
        open($LISTFILE, '<', $filename)
            or die 'Error: unable to open file ' . $filename . ' (' . $! . ')';
    }

    # Job identifier tracking for parallel execution.
    my @jobid_list = ();
    my $job_number = 0;

    # Iterate over identifiers, submitting each job
    while (<$LISTFILE>) {
        my $line = $_;
        chomp($line);
        if ($line ne '') {
            &print_debug_message('list_file_submit_job', 'line: ' . $line, 2);
            if ($line =~ m/\w:\w/) {
                # Check this is an identifier
                my $seq_id = $line;
                print STDERR "Submitting job for: $seq_id\n"
                    if ($outputLevel > 0);
                $job_number++;
                my $job_id = &submit_job($seq_id, $seq_id);
                my $job_info_str =
                    sprintf('%s %s %d %d', $job_id, $seq_id, 0, $job_number);
                push(@jobid_list, $job_info_str);
            }
            else {
                print STDERR
                    "Warning: line \"$line\" is not recognised as an identifier\n";
            }

            # Parallel mode, wait for job(s) to finish to free slots.
            while ($params{'maxJobs'} > 1
                && scalar(@jobid_list) >= $params{'maxJobs'}) {
                &_job_list_poll(\@jobid_list);
                print_debug_message('list_file_submit_job',
                    'Remaining jobs: ' . scalar(@jobid_list), 1);
            }
        }
    }
    close $LISTFILE;

    # Parallel mode, wait for remaining jobs to finish.
    while ($params{'maxJobs'} > 1 && scalar(@jobid_list) > 0) {
        &_job_list_poll(\@jobid_list);
        print_debug_message('list_file_submit_job',
            'Remaining jobs: ' . scalar(@jobid_list), 1);
    }
    print_debug_message('list_file_submit_job', 'End', 1);
}


=head2 load_data()

Load sequence data from file or option specified on the command-line.

  &load_data();

=cut

sub load_data {
    print_debug_message('load_data', 'Begin', 1);
    my $retSeq;

    # Query sequence
    if (defined($ARGV[0])) {                  # Bare option
        if (-f $ARGV[0] || $ARGV[0] eq '-') { # File
            $retSeq = &read_file($ARGV[0]);
        }
        else { # DB:ID or sequence
            $retSeq = $ARGV[0];
        }
    }
    if ($params{'sequence'}) {                                      # Via --sequence
        if (-f $params{'sequence'} || $params{'sequence'} eq '-') { # File
            $retSeq = &read_file($params{'sequence'});
        }
        else { # DB:ID or sequence
            $retSeq = $params{'sequence'};
        }
    }
    print_debug_message('load_data', 'End', 1);
    return $retSeq;
}

=head2 load_params()

Load job parameters from command-line options.

  &load_params();

=cut

sub load_params {
    print_debug_message('load_params', 'Begin', 1);

    # Pass default values and fix bools (without default value)
    if (!$params{'mx'}) {
        $params{'mx'} = 'BLOSUM62'
    }

    if (!$params{'nobias'}) {
        $params{'nobias'} = 'true'
    }

    if (!$params{'alignView'}) {
        $params{'alignView'} = 'true'
    }

    print_debug_message('load_params', 'End', 1);
}

=head2 client_poll()

Client-side job polling.

  &client_poll($job_id);

=cut

sub client_poll {
    print_debug_message('client_poll', 'Begin', 1);
    my $jobid = shift;
    my $status = 'PENDING';

    # Check status and wait if not finished. Terminate if three attempts get "ERROR".
    my $errorCount = 0;
    while ($status eq 'RUNNING'
        || $status eq 'PENDING'
        || ($status eq 'ERROR' && $errorCount < 2)) {
        $status = rest_get_status($jobid);
        print STDERR "$status\n" if ($outputLevel > 0);
        if ($status eq 'ERROR') {
            $errorCount++;
        }
        elsif ($errorCount > 0) {
            $errorCount--;
        }
        if ($status eq 'RUNNING'
            || $status eq 'PENDING'
            || $status eq 'ERROR') {

            # Wait before polling again.
            usleep($checkInterval);
        }
    }
    print_debug_message('client_poll', 'End', 1);
    return $status;
}

=head2 get_results()

Get the results for a job identifier.

  &get_results($job_id);

=cut

sub get_results {
    print_debug_message('get_results', 'Begin', 1);
    my $jobid = shift;
    print_debug_message('get_results', 'jobid: ' . $jobid, 1);
    my $seq_id = shift;
    print_debug_message('get_results', 'seq_id: ' . $seq_id, 1) if ($seq_id);

    my $output_basename = $jobid;

    # Verbose
    if ($outputLevel > 1) {
        print 'Getting results for job ', $jobid, "\n";
    }

    # Check status, and wait if not finished
    client_poll($jobid);

    # Default output file names use JobId, however the name can be specified...
    if (defined($params{'outfile'})) {
        $output_basename = $params{'outfile'};
    }
    # Or use sequence identifer.
    elsif (defined($params{'useSeqId'} && defined($seq_id) && $seq_id ne '')) {
        $output_basename = $seq_id;

        # Make safe to use as a file name.
        $output_basename =~ s/\W/_/g;
    }

    # Use JobId if output file name is not defined
    else {
        unless (defined($params{'outfile'})) {
            $params{'outfile'} = $jobid;
            $output_basename = $jobid;
        }
    }

    # Get list of data types
    my (@resultTypes) = rest_get_result_types($jobid);


    # Get the data and write it to a file
    if (defined($params{'outformat'})) {
        # Specified data type
        # check to see if there are multiple formats (comma separated)
        my $sep = ",";
        my (@multResultTypes);
        if ($params{'outformat'} =~ /$sep/) {
            @multResultTypes = split(',', $params{'outformat'});
        }
        else {
            @multResultTypes[0] = $params{'outformat'};
        }
        # check if the provided formats are recognised
        foreach my $inputType (@multResultTypes) {
            my $expectation = 0;
            foreach my $resultType (@resultTypes) {
                if ($resultType->{'identifier'} eq $inputType && $expectation eq 0) {
                    $expectation = 1;
                }
            }
            if ($expectation ne 1) {
                die 'Error: unknown result format "' . $inputType . '"';
            }
        }
        # if so get the files
        my $selResultType;
        foreach my $resultType (@resultTypes) {
            if (grep {$_ eq $resultType->{'identifier'}} @multResultTypes) {
                $selResultType = $resultType;
                my $result = rest_get_result($jobid, $selResultType->{'identifier'});
                if (defined($params{'outfile'}) && $params{'outfile'} eq '-') {
                    write_file($params{'outfile'}, $result);
                }
                else {
                    write_file(
                        $output_basename . '.'
                            . $selResultType->{'identifier'} . '.'
                            . $selResultType->{'fileSuffix'},
                        $result
                    );
                }
            }
        }
    }
    else { # Data types available
        # Write a file for each output type
        for my $resultType (@resultTypes) {
            if ($outputLevel > 1) {
                print STDERR 'Getting ', $resultType->{'identifier'}, "\n";
            }
            my $result = rest_get_result($jobid, $resultType->{'identifier'});
            if (defined($params{'outfile'}) && $params{'outfile'} eq '-') {
                write_file($params{'outfile'}, $result);
            }
            else {
                write_file(
                    $output_basename . '.'
                        . $resultType->{'identifier'} . '.'
                        . $resultType->{'fileSuffix'},
                    $result
                );
            }
        }
    }
    print_debug_message('get_results', 'End', 1);
}

=head2 read_file()

Read a file into a scalar. The special filename '-' can be used to read from
standard input (STDIN).

  my $data = &read_file($filename);

=cut

sub read_file {
    print_debug_message('read_file', 'Begin', 1);
    my $filename = shift;
    print_debug_message('read_file', 'filename: ' . $filename, 2);
    my ($content, $buffer);
    if ($filename eq '-') {
        while (sysread(STDIN, $buffer, 1024)) {
            $content .= $buffer;
        }
    }
    else {
        # File
        open(my $FILE, '<', $filename)
            or die "Error: unable to open input file $filename ($!)";
        while (sysread($FILE, $buffer, 1024)) {
            $content .= $buffer;
        }
        close($FILE);
    }
    print_debug_message('read_file', 'End', 1);
    return $content;
}

=head2 write_file()

Write data to a file. The special filename '-' can be used to write to
standard output (STDOUT).

  &write_file($filename, $data);

=cut

sub write_file {
    print_debug_message('write_file', 'Begin', 1);
    my ($filename, $data) = @_;
    print_debug_message('write_file', 'filename: ' . $filename, 2);
    if ($outputLevel > 0) {
        print STDERR 'Creating result file: ' . $filename . "\n";
    }
    if ($filename eq '-') {
        print STDOUT $data;
    }
    else {
        open(my $FILE, '>', $filename)
            or die "Error: unable to open output file $filename ($!)";
        syswrite($FILE, $data);
        close($FILE);
    }
    print_debug_message('write_file', 'End', 1);
}

=head2 usage()

Print program usage message.

  &usage();

=cut

sub usage {
    print STDERR <<EOF
EMBL-EBI HMMER 3 phmmer Perl Client:

Protein function analysis with HMMER 3 phmmer.

[Required (for job submission)]
  --email               E-mail address.
  --database            Sequence Database.
  --sequence            The input sequence can be entered directly into this form.
                        The sequence can be be in FASTA or UniProtKB/Swiss-Prot
                        format. A partially formatted sequence is not accepted.
                        Adding a return to the end of the sequence may help certain
                        applications understand the input. Note that directly using
                        data from word processors may yield unpredictable results as
                        hidden/control characters may be present.

[Optional]
  --incE                Significance E-values[Sequence].
  --incdomE             Significance E-values[Hit].
  --E                   Report E-values[Sequence].
  --domE                Report E-values[Hit].
  --incT                Significance bit scores[Sequence].
  --incdomT             Significance bit scores[Hit].
  --T                   Report bit scores[Sequence].
  --domT                Report bit scores[Hit].
  --popen               Gap Penalties[open].
  --pextend             Gap Penalties[extend].
  --mx                  Gap Penalties[Substitution scoring matrix].
  --nobias              Filters.
  --alignView           Output alignment in result.
  --evalue              Expectation value cut-off for reporting target profiles in
                        the per-target output.

[General]
  -h, --help            Show this help message and exit.
  --async               Forces to make an asynchronous query.
  --title               Title for job.
  --status              Get job status.
  --resultTypes         Get available result types for job.
  --polljob             Poll for the status of a job.
  --pollFreq            Poll frequency in seconds (default 3s).
  --jobid               JobId that was returned when an asynchronous job was submitted.
  --outfile             File name for results (default is JobId; for STDOUT).
  --acc                 Get accession ID, how many from top. The default is 20.
  --multifasta          Treat input as a set of fasta formatted sequences.
  --useSeqId            Use sequence identifiers for output filenames.
                        Only available in multi-fasta and multi-identifier modes.
  --maxJobs             Maximum number of concurrent jobs. Only
                        available in multifasta or list file modes.
  --outformat           Result format(s) to retrieve. It accepts comma-separated values.
  --params              List input parameters.
  --paramDetail         Display details for input parameter.
  --quiet               Decrease output.
  --verbose             Increase output.
  --baseUrl             Base URL. Defaults to:
                        https://www.ebi.ac.uk/Tools/services/rest/hmmer3_phmmer

Synchronous job:
  The results/errors are returned as soon as the job is finished.
  Usage: perl $scriptName --email <your\@email.com> [options...] <SeqFile|SeqID(s)>
  Returns: results as an attachment

Asynchronous job:
  Use this if you want to retrieve the results at a later time. The results
  are stored for up to 24 hours.
  Usage: perl $scriptName --async --email <your\@email.com> [options...] <SeqFile|SeqID(s)>
  Returns: jobid

Check status of Asynchronous job:
  Usage: perl $scriptName --status --jobid <jobId>

Retrieve job data:
  Use the jobid to query for the status of the job. If the job is finished,
  it also returns the results/errors.
  Usage: perl $scriptName --polljob --jobid <jobId> [--outfile string]
  Returns: string indicating the status of the job and if applicable, results
  as an attachment.

Further information:
  https://www.ebi.ac.uk/Tools/webservices and
    https://github.com/ebi-wp/webservice-clients

Support/Feedback:
  https://www.ebi.ac.uk/support/
EOF
}

=head1 FEEDBACK/SUPPORT

Please contact us at L<https://www.ebi.ac.uk/support/> if you have any
feedback, suggestions or issues with the service or this client.

=cut