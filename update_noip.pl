#!/usr/bin/env perl
use strict;
use warnings;
use 5.10.0;
use Term::ReadKey;

# GLOBALS and DEFAULT VALUEs
my $USER = 'email@host.com';    # Default user
my $HOST = 'your.noip.host';    # Default hostname
check_config();

my $PASS = undef;
my $IP = get_ip_address();
my $RUN = 1;

if (defined($ARGV[0]) && $ARGV[0] eq '-x') {
    say "\n** user:$USER  ip:$IP  host:$HOST **";
    $PASS = get_passwd('Password: ');
    send_update();
    $RUN = 0;
}

while ($RUN) {
    prompt();
    chomp(my $res = readline);
    $RUN = process_response($res);
}

sub prompt {
    my $passwd = defined($PASS) ? '***' : '?';
    chomp(my $prompt = <<END);

** user:$USER  pass:$passwd  ip:$IP  host:$HOST **
    x               execute the update
    p               set password
    i <ip address>  set IP
    u <user>        set username
    h <hostname>    set hostname
    q               quit
Action: 
END
    print $prompt;
}

sub process_response {
    my $res = shift;

    return 0 if $res eq 'q';
    return set_user($res) if $res =~ /^u/;
    return set_host($res) if $res =~ /^h/;
    return set_passwd($res) if $res =~ /^p/;
    return set_ip($res) if $res =~ /^i/;
    return send_update() if $res =~ /^x/;
    return 1;
}

sub set_ip {
    my (undef,$ip) = split ' ', shift;
    $ip ||= $IP;
    say "\nUpdating noip: $ip";
    $IP = $ip;
    return 1;
}

sub set_host {
    my (undef,$host) = split ' ', shift;
    $host ||= $HOST;
    say "\nSet Hostname: $host";
    $HOST = $host;
    return 1;
}

sub set_user {
    my (undef,$user) = split ' ', shift;
    $user ||= $USER;
    say "\nSet Username: $user";
    $USER = $user;
    return 1;
}

sub set_passwd {
    $PASS = get_passwd('Password: ');
    say "\nSet password: ***";
    return 1;
}

sub get_ip_address {
    my $html = `curl www.ipchicken.com 2> /dev/null`;
    $html =~ /(\d+.\d+.\d+.\d+)<br>/m;
    my $ip = $1;
    return $ip;
}

sub get_passwd {
    print $_[0] || "Enter Password: ";
    ReadMode('noecho');
    chomp( my $p = ReadLine(0) );
    ReadMode 'normal';
    print "\n";
    return $p;
}

sub get_input {
    print $_[0] || "Enter input: ";
    chomp( my $p = ReadLine(0) );
    return $p;
}

sub send_update {
    $PASS = get_passwd('Password: ') unless $PASS;
    $IP = get_input('IP: ') unless $IP;

    my $cmd = 'curl -u '. $USER .':'. $PASS 
            . ' "http://dynupdate.no-ip.com/nic/update?'
            . 'hostname='. $HOST .'&myip='. $IP .'"';
    say "\n*** ERROR: Password not set. Update aborted ***" unless $PASS;
    say "\n*** ERROR: IP address not set. Update aborted ***" unless $IP;
    return 1 unless $PASS;

    system($cmd);
}

sub check_config {
    say 'Please setup $USER in the script first.' if $USER eq 'email@host.com';
    say 'Please setup $HOST in the script first.' if $HOST eq 'your.noip.host';
    exit if $USER eq 'email@host.com' || $HOST eq 'your.noip.host';
}


=head1 NAME

    update_noip.pl - A No-IP dynamic update client for Linux

=head1 SYNOPSIS

    update_noip.pl              # Interactive script
    update_noip.pl -x           # CLI version

=head1 DEPENDENCIES

    curl
        To perform the update and check current ip.
        https://curl.haxx.se/download.html

    Term::ReadKey
        To read passwords without echo.
        http://search.cpan.org/~jstowe/TermReadKey-2.33/ReadKey.pm

=head1 AUTHOR

    Hoe Kit CHEW, <hoekit at gmail.com>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2014 by Chew Hoe Kit - same terms as Perl itself.

=cut

