variable "aws_region" {
  description = "AWS region where the resources is deployed"
  type        = string

}

variable "bastio_server_instance_type" {
  description = "Type of the  instance for the Bastion Server"
  type        = string

}

variable "db_server_instance_type" {
  description = "Type of the  instance for the DB Server"
  type        = string

}

variable "web_server_instance_type" {
  description = "Type of the  instance for the WEB Server"
  type        = string

}
variable "key_pair_name" {
  description = "Name of the SSH key_paiir "
  type        = string

}

variable "my_ip_address" {
  description = "Local Machine IP address"
  type        = string


}
variable "my_profile" {
  description = "AWS profile configured for the task"


}
variable "my_password" {
  description = "password"
  type        = string

}
