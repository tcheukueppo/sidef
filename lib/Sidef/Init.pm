
# This modules is used to require all modules at once.

# Generated by:
# find . | perl -nE 'chomp; if(s/\.pm\z//){s{^\./}{};s{/}{::}g; print "require Sidef::$_;\n"}'

use 5.014;
use strict;
use warnings;

use lib '..';

require Sidef::Convert::Convert;
require Sidef::Base;
require Sidef::Types::Hash::Hash;
require Sidef::Types::Array::Array;
require Sidef::Types::Number::Integer;
require Sidef::Types::Number::Number;
require Sidef::Types::Number::Float;
require Sidef::Types::String::Single;
require Sidef::Types::String::Double;
require Sidef::Types::String::String;
require Sidef::Types::Bool::Bool;
require Sidef::Types::Regex::Regex;
require Sidef::Lexer;
require Sidef::Variable::Number;
require Sidef::Variable::String;
require Sidef::Variable::Bool;
require Sidef::Variable::Array;
require Sidef::Variable::Hash;
require Sidef::Variable::Regex;

1;
