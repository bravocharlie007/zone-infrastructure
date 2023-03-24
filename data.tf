data "terraform_remote_state" "compute" {
  backend =  "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.previous_workspace
    }
  }
}
