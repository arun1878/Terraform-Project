resource "aws_instance" "web" {
  count         = "${var.ec2_count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${var.subnet_id}"
  key_name = "Terra"
  user_data = <<EOF
           #!/bin/bash
           wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
		      tar -xvf node_exporter-1.1.2.linux-amd64.tar.gz
           sudo mv node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin/
           rm -rf node_exporter-1.1.2.linux-* 
           cd /usr/local/bin/
           nohup ./node_exporter & 
    EOF
  tags = {
    Name = "Test-Module"
  }
}