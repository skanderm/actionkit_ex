defmodule ActionkitTest do
  use ExUnit.Case
  doctest Ak

  test "login claiming works" do
    Ak.Signup.start_link
    Ak.DialerLogin.record_login_claimed(%{email: "ben.paul.ryan.packer@gmail.com", phone: "5555555555", zip: "75225"}, "JdVolunteer1", "jd")
    login = Ak.DialerLogin.existing_login_for_email("ben.paul.ryan.packer@gmail.com", "jd")
    assert login == "JdVolunteer1"
  end

  test "signing up works" do
    Ak.Signup.start_link
    Ak.Signup.process_signup("Justice Democrats", %{email: "ben.paul.ryan.packer@gmail.com", phone: "5555555555", zip: "75225"})
  end

  test "signing a petition works" do
    Ak.List.start_link
    Ak.Petition.start_link
    Ak.Petition.process_petition_sign("from-cosmic", %{email: "ben.paul.ryan.packer@gmail.com", phone: "5555555555", zip: "75225"})
  end
end
