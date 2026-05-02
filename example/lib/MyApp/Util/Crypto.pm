package MyApp::Util::Crypto;
use strict;
use warnings;
use Exporter 'import';
use Digest::SHA qw(sha256_hex sha512_hex hmac_sha256_hex);

our @EXPORT_OK = qw(hash_password verify_password generate_token hmac_sign);

sub hash_password {
    my ($password, $salt) = @_;
    $salt //= _random_salt();
    return "$salt\$" . sha256_hex($salt . $password);
}

sub verify_password {
    my ($password, $hash) = @_;
    my ($salt) = split /\$/, $hash;
    return hash_password($password, $salt) eq $hash;
}

sub generate_token {
    my $len = shift // 32;
    return substr(sha512_hex(time . rand() . $$), 0, $len);
}

sub hmac_sign {
    my ($data, $key) = @_;
    return hmac_sha256_hex($data, $key);
}

sub _random_salt {
    return substr(sha256_hex(rand() . time . $$), 0, 16);
}

1;
