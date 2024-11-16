This is where all logins and attempts to connect will appear.
<p>
  It will include date and time, mac addresses and ip addresses
  and dhcp requests and depending on the client hostname. NOTE NOT
  ALL ADDRESSES IN THIS AREA HAVE BEEN WHITELISTED. IF THE MAC/IP
  DOESN'T HAVE A USERNAME OR AGREED AS THE TRANSACTION THEN THEY ARE
  PROABBLY NOT WHITELISTED.
</p>
<p>
  There will be 2 files for each client:
  <ul>
    <li>.mac Log of logins and dhcp with that mac address</li>
    <li>.ip log of logins and dhcp with that ip address</li>
  </ul>
</p>
<p>
  Each file is a text file that contains each line like this:<br>
  [time_and_date] [transaction_name/username] [mac_address] [ip_address] [hostname]
</p>
<p>
  if transaction_name begins with <b>DHCP_</b> then its a dhcp transaction<br>
  It can have DHCP_add DHCP_old and DHCP_del<br>
</p>
<p>
  if transaction name is agreed or a username then the that device is proabbly whitelisted.
</p>
