use Errors::Errors;

my $obj = Errors::Errors->new();

print "\nTest";

$obj->install('onExit',\&testExit);

sub testExit
{
 print "...ok\n";
}