#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 111;

use Sidef;

my $o = 'Sidef::Types::Number::Number';

my $pi = $o->pi;

my $d = $o->new(45);
my $r = $pi->div($o->new(4));

sub rad2deg {
    $o->new(180)->div($pi)->mul($_[0]);
}

sub deg2rad {
    $pi->div($o->new(180))->mul($_[0]);
}

like($r->sin, qr/^0\.7071067811865/);
like($r->cos, qr/^0\.7071067811865/);

like(deg2rad($d)->sin, qr/^0\.7071067811865/);
like(deg2rad($d)->cos, qr/^0\.7071067811865/);

is($r->tan, $o->new(1));
is($r->cot, $o->new(1));

my $asin = $r->sin->asin;
is($asin,          $pi->div($o->new(4)));
is(rad2deg($asin), $d);

my $acos = $r->cos->acos;
is($acos,          $pi->div($o->new(4)));
is(rad2deg($acos), $d);

my $atan = $r->tan->atan;
is($atan,          $pi->div($o->new(4)));
is(rad2deg($atan), $d);

my $acot = $r->cot->acot;
is($acot,          $pi->div($o->new(4)));
is(rad2deg($acot), $d);

like($o->new(1)->atan2($o->new(1))->mul($o->new(4)), qr/^3.14159/);

#
## More tests
#

{
    my $x = $o->new(5);
    my $y = $x->inv;

    my $type = 'Sidef::Types::Number::Number';

    my %tests = (
          asin  => [[$type, qr/^1\.570796326.*?\s*\+\s*2\.2924[^i]*i\z/], [$type, qr/^0\.2013579207903307/],],
          sinh  => [[$type, qr/^74\.203210577788758/],                    [$type, qr/^0\.2013360025410939/],],
          asinh => [[$type, qr/^2\.312438341272752/],                     [$type, qr/^0\.198690110349241/],],
          acos  => [[$type, qr/^-2\.292431669561177[^i]*i\z/],            [$type, qr/^1\.36943840600456582/],],
          cosh  => [[$type, qr/^74\.20994852478784444/],                  [$type, qr/^1\.020066755619075846/],],
          acosh => [[$type, qr/^2\.292431669561177687/],                  [$type, qr/^1\.369438406004565827[^i]*i\z/],],
          tan   => [[$type, qr/^-3\.3805150062465856369/],                [$type, qr/^0\.202710035508672483321/],],
          atan  => [[$type, qr/^1\.373400766945015860861/],               [$type, qr/^0\.197395559849880758370/],],
          tanh  => [[$type, qr/^0\.9999092042625951312109/],              [$type, qr/^0\.1973753202249040007381/],],
          atanh => [[$type, qr/^0\.2027325540540.*?\s*\+\s*1\.5707963267948966[^i]*i\z/], [$type, qr/^0\.20273255405408219/],],
          sec   => [[$type, qr/^3\.525320085816088406/],           [$type, qr/^1\.020338844941192689/],],
          asec  => [[$type, qr/^1\.36943840600456582777/],         [$type, qr/^-2\.29243166956117768[^i]*i\z/],],
          sech  => [[$type, qr/^0\.01347528222130455730/],         [$type, qr/^0\.98032799764472533487/],],
          asech => [[$type, qr/^1\.36943840600456582777[^i]*i\z/], [$type, qr/^2\.2924316695611776878007873/],],
          csc   => [[$type, qr/^-1\.04283521277140581978311985/],  [$type, qr/^5\.033489547672344202426096367/],],
          acsc  => [
                   [$type, qr/^0\.2013579207903307914551255522/],
                   [$type, qr/^1\.570796326794896619231321.*?\s*\+\s*2\.29243166956117768780[^i]*i\z/],
                  ],
          csch  => [[$type, qr/^0\.0134765058305890866553818/],  [$type, qr/^4\.9668215688145168965134827/],],
          acsch => [[$type, qr/^0\.1986901103492414064746369/],  [$type, qr/^2\.3124383412727526202535623/],],
          cot   => [[$type, qr/^-0\.2958129155327455404277671/], [$type, qr/^4\.93315487558689365736801632/],],
          acot  => [[$type, qr/^0\.19739555984988075837004976/], [$type, qr/^1\.37340076694501586086127192/],],
          coth  => [[$type, qr/^1\.00009080398201937553665792/], [$type, qr/^5\.06648956343947271363178778/],],
          acoth => [[$type, qr/^0\.202732554054082190989006557/],
                    [$type, qr/^0\.2027325540540821909.*?\s*\+\s*1\.5707963267948966192[^i]*i/],
                   ],
                );

    foreach my $k (keys %tests) {
        my $v = $tests{$k};

        my $r1 = $x->$k;
        is(ref($r1), $v->[0][0], "1) $k");
        like("$r1", $v->[0][1], "1) $k");

        my $r2 = $y->$k;
        is(ref($r2), $v->[1][0], "2) $k");
        like("$r2", $v->[1][1], "2) $k");
    }

    #
    ## atan2() tests
    #
    my $r = $x->atan2($x);
    is(ref($r), $type);
    like("$r", qr/^0\.785398163397448309/);

    $r = $x->atan2($y);
    is(ref($r), $type);
    like("$r", qr/^1\.530817639671606/);

    $r = $y->atan2($x);
    is(ref($r), $type);
    like("$r", qr/^0\.0399786871232900414/);

    $r = $y->atan2($y);
    is(ref($r), $type);
    like("$r", qr/^0\.785398163397448309/);

}
