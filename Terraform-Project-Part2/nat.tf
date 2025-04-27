resource "aws_eip" "nat_gw" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.main]
}