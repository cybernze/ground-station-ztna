# ─────────────────────────────────────────
# VPC — Red privada principal
# Analogía: tu parcela privada en la ciudad AWS
# ─────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # 65,536 IPs privadas disponibles
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# Internet Gateway — Puerta hacia internet
# Analogía: la verja principal de tu parcela
# ─────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# Subred Pública — Zona accesible desde internet
# Analogía: jardín delantero de tu parcela
# ─────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" # 256 IPs en esta subred
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # EC2 recibe IP pública automáticamente

  tags = {
    Name    = "${var.project_name}-subnet-public"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# Route Table — Tabla de rutas
# Analogía: señales de tráfico dentro de tu parcela
# ─────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # Todo tráfico externo...
    gateway_id = aws_internet_gateway.main.id # ...sale por el Internet Gateway
  }

  tags = {
    Name    = "${var.project_name}-rt-public"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────
# Security Group — Firewall / Portero
# Reglas: solo tu IP puede hacer SSH (22)
#         solo tu IP puede acceder a la API mTLS (8443)
#         todo el tráfico saliente está permitido
# ─────────────────────────────────────────
resource "aws_security_group" "ground_station" {
  name        = "${var.project_name}-sg"
  description = "Security group for Ground Station API server"
  vpc_id      = aws_vpc.main.id

  # SSH — solo desde tu IP
  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # API mTLS — solo desde tu IP (en Fase 4 será el cliente con certificado)
  ingress {
    description = "mTLS API port from operator"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Egress — tráfico saliente libre (para instalar paquetes, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# Key Pair — Par de claves SSH
# Terraform lee tu clave pública local y la registra en AWS
# ─────────────────────────────────────────
resource "aws_key_pair" "operator" {
  key_name   = "${var.project_name}-key"
  public_key = var.operator_public_key
}

# ─────────────────────────────────────────
# EC2 Instance — Tu servidor virtual
# Analogía: el ordenador dentro de tu jardín
# ─────────────────────────────────────────
resource "aws_instance" "ground_station" {
  ami                    = var.ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ground_station.id]
  key_name               = aws_key_pair.operator.key_name

  # Script que se ejecuta al arrancar la instancia por primera vez
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker git
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }
}
