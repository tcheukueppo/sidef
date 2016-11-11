package Sidef::Math::Math {

    use utf8;
    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Number::Number;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub gcd {
        my ($self, @list) = @_;

        my $gcd = $list[0];
        foreach my $i (1 .. $#list) {
            last if ($gcd->is_one);
            $gcd = $gcd->gcd($list[$i]);
        }

        $gcd;
    }

    sub lcm {
        my ($self, @list) = @_;

        my $lcm = $list[0];
        foreach my $i (1 .. $#list) {
            $lcm = $lcm->lcm($list[$i]);
        }

        $lcm;
    }

    sub sum {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::ZERO;
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        $sum;
    }

    sub prod {
        my ($self, @list) = @_;

        my $prod = Sidef::Types::Number::Number::ONE;
        foreach my $n (@list) {
            $prod = $prod->mul($n);
        }

        $prod;
    }

    *product = \&prod;

    sub max {
        my ($self, @list) = @_;

        my $max = $list[0];
        foreach my $i (1 .. $#list) {
            $max = $max->max($list[$i]);
        }

        $max;
    }

    sub min {
        my ($self, @list) = @_;

        my $min = $list[0];
        foreach my $i (1 .. $#list) {
            $min = $min->min($list[$i]);
        }

        $min;
    }

    sub avg {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::ZERO;
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        my $n = Sidef::Types::Number::Number->new(scalar(@list));
        $sum->div($n);
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;
        $step //= Sidef::Types::Number::Number::ONE;
        state $two = Sidef::Types::Number::Number->_set_uint(2);
        ($from->add($to))->mul($to->sub($from)->div($step)->add(Sidef::Types::Number::Number::ONE))->div($two);
    }

    sub map {
        my ($self, $value, $in_min, $in_max, $out_min, $out_max) = @_;
        ($value->sub($in_min))->mul($out_max->sub($out_min))->div($in_max->sub($in_min))->add($out_min);
    }

    sub map_range {
        my ($self, $amount, $from, $to) = @_;
        Sidef::Types::Range::RangeNumber->new($from, $to, $to->sub($from)->div($amount),);
    }

    sub number_to_percentage {
        my ($self, $num, $from, $to) = @_;

        my $sum  = $to->sub($from)->abs;
        my $dist = $num->sub($to)->abs;

        state $hundred = Sidef::Types::Number::Number->_set_uint(100);
        ($sum->sub($dist))->div($sum)->mul($hundred);
    }

    *num2percent = \&number_to_percentage;

    our $AUTOLOAD;

    #
    ## This method is highly deprecated!
    #
    sub AUTOLOAD {
        my ($self, $x, @args) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my $code =
          ref($x)
          ? UNIVERSAL::can($x,                             $method)
          : UNIVERSAL::can('Sidef::Types::Number::Number', $method);

        defined($code)
          ? $code->(defined($x) ? ($x, @args) : ())
          : do {
            my $arg = join(', ', map { defined($_) ? $_ : 'nil' } (@_ > 1 ? ($x, @args) : ()));
            die "[ERROR] Undefined method Math.$method($arg)";
          };
    }

}

1
