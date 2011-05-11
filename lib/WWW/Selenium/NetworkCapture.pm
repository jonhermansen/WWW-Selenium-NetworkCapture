package WWW::Selenium::NetworkCapture;
# Nicked from http://code.google.com/p/selenium-profiler/source/browse/trunk/web_profiler.py

use XML::Simple qw/XMLin/;
use DateTime::Format::Strptime;

sub new {
    my ($class, $xml_blob) = @_;

    my %self;
    $self->{xml_blob} = $xml_blob;
    if (length $xml_blob < 50) {
	die;
    } else {
	$self->{dom} = XMLin($xml_blob);
    }

    bless $self, $class or die "Can't bless $class: $!";
    return $self;
}

sub get_content_size {
    my ($self) = @_;

    my @byte_sizes;
    foreach my $child (@{$self->{dom}->{entry}}) {
	push @byte_sizes, $child->{bytes};
    }

    my $total_size;
    $total_size += $_ for @byte_sizes;
    $total_size = $total_size / 1000.0;

    return $total_size;
}

sub get_num_requests {
    my ($self) = @_;

    return scalar @{$self->{dom}->{entry}};
}

sub get_http_status_codes {
    my ($self) = @_;

    my %status_map;
    foreach my $child (@{$self->{dom}->{entry}}) {
	if ($status_map{$child->{statusCode}}) {
	    $status_map{$child->{statusCode}} += 1;
	} else {
	    $status_map{$child->{statusCode}} = 1;
	}
    }

    return %status_map;
}

sub get_http_details {
    my ($self) = @_;

    my @http_details;
    foreach my $child (@{$self->{dom}->{entry}}) {
	my $url = $child->{url};
	my $url_stem = (split '\?', $url)[0];
	my $doc = '/' . (split '/', $url_stem)[-1];
	my $status = int $child->{statusCode};
	my $method = ($child->{method} =~ /([^']+)/)[0];
	my $size = int $child->{bytes};
	my $time = int $child->{timeInMillis};
	push @http_details, [$status, $method, $doc, $size, $time];
    }

    return @http_details;
}

sub get_file_extension_stats {
    my ($self) = @_;

    my %file_ext_map = {}; # k=extension v=(count,size) 
    foreach my $child (@{$self->{dom}->{entry}}) {
	my $size = $child->{bytes} / 1000.0;
	my $url = $child->{url};
	my $url_stem = (split '\?', $url)[0];
	my $doc = '/' . (split '/', $url_stem)[-1];
	use vars qw/$file_ext/;
	if ($doc =~ /\./ && $doc !~ /\.$/) {
	    $file_ext = (split '\.', $doc)[-1];
	} else {
	    $file_ext = 'unknown';
	}

	if ($file_ext_map{$file_ext}) {
	    ${$file_ext_map{$file_ext}}[0] += 1;
	    ${$file_ext_map{$file_ext}}[1] += $size;
	} else {
	    $file_ext_map{$file_ext} = [1, $size];
	}
    }

    return %file_ext_map;
}

sub get_network_times {
    my ($self) = @_;

    my (@timings, @start_times, @end_times);
    foreach my $child (@{$self->{dom}->{entry}}) {
	push @timings, $child->{timeInMillis};
	push @start_times, $child->{start};
	push @end_times, $child->{end};
    }
    @start_times = sort @start_times;
    @end_times = sort @end_times;
    my $start_first_request = $self->convert_time($start_times[0]);
    my $end_first_request = $self->convert_time($end_times[0]);
    my $end_last_request = $self->convert_time($end_times[-1]);

    return ($start_first_request, $end_first_request, $end_last_request);
}

sub convert_time {
    my ($self, $date_string) = @_;

    if ($date_string =~ /-/) {
	my $split_char = '-';
    } else {
	my $split_char = '\+';
    }

    $date_string =~ s/-//g;
    my $strp = DateTime::Format::Strptime->new(
	pattern => '%Y%m%dT%H:%M:%S',
    );
    my $dt = $strp->parse_datetime($date_string);
    return $dt;
}

1;
