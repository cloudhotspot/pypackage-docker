require "serverspec"
require "docker"

describe "Dockerfile" do 
  before(:all) do 
    image = Docker::Image.build_from_dir('.')

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id
  end

  it "installs the correct version of Ubuntu" do 
    expect(os_version).to include("Ubuntu 14")
  end

  it "installs required packages" do
    expect(package("python")).to be_installed
  end

  def os_version
    command("lsb_release -a").stdout
  end
end