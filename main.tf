resource "local_file" "pet" {
  filename = "/root/tope/pet.txt"
  content = var.content
}

output "pet-content" {
  value = local_file.pet.content
}

variable "content" {
  type = string
  description = "content for the pet"
  default = "This is a pet file"
}