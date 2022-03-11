<%@ Page Language="C#" %>

<!-- 
    https://vqanew_rbl:444/ExecuteDaemons.aspx
 -->
<script language="c#" runat="server">

    Microsoft.Web.Administration.ServerManager serverManager = new Microsoft.Web.Administration.ServerManager();
    System.Diagnostics.ProcessStartInfo processInfo;
    System.Diagnostics.Process process;

    public void Page_Load(object sender, EventArgs e)
    {
        Page.Server.ScriptTimeout = 7200;
        var environment = Environment.SelectedValue;
        //PageInfo.InnerHtml = "<h2>Environment: " + environment + "</h2>";
    }
    public void Environment_SelectedIndexChanged(Object sender, EventArgs e)
    {
        var environment = Environment.SelectedValue;
        //PageInfo.InnerHtml = "<h2>Environment: " + environment + "</h2>";
    }

    public void RunDaemonService(string daemonName, string parameters)
    {
        var environment = Environment.SelectedValue;
        string output = "";
        string error = "";
        var exitCode = 0;
        string param = string.Empty;
        try
        {
            if (!string.IsNullOrEmpty(parameters))
                processInfo = new System.Diagnostics.ProcessStartInfo(System.IO.Path.Combine("C:\\blds\\" + environment + "\\Daemons", daemonName), parameters);
            else
                processInfo = new System.Diagnostics.ProcessStartInfo(System.IO.Path.Combine("C:\\blds\\" + environment + "\\Daemons", daemonName));

            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            processInfo.RedirectStandardError = true;
            processInfo.RedirectStandardOutput = true;
            PageInfo.InnerHtml = PageInfo.InnerHtml + "<h4>Running Daemon [" + daemonName + "]</h4>";
            process = System.Diagnostics.Process.Start(processInfo);
            output = process.StandardOutput.ReadToEnd();
            error = process.StandardError.ReadToEnd();
            process.WaitForExit(300000); //5 Minutos
            exitCode = process.ExitCode;
            param = string.IsNullOrEmpty(parameters) ? "" : string.Concat("| ", parameters);
            if (exitCode != 0 || error.Contains("ERR!") || error.Contains("Error") || error.Contains("error"))
            {
                PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing...<br />ExitCode:{1} Error Message:{2}<br />", param, exitCode, error) + "<br />";
            }
            output = string.IsNullOrEmpty(output) ? "No Response..." : output;
            PageInfo.InnerHtml = PageInfo.InnerHtml + output + "<br/>";
        }
        catch (Exception ex)
        {
            PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing...<br />Error Message:{1}<br />", param, ex.Message) + "<br />";
        }
    }

    public void DaemonRunit(Object sender, EventArgs e)
    {
        var environment = Environment.SelectedValue;
        PageInfo.InnerHtml = "<h2>Environment: " + environment + "</h2><br />";
        
        string messagingDaemon = "Infocorp.Framework.MessagingDaemon.exe";
        RunDaemonService(messagingDaemon, null);

        string notificationsDaemon = "Infocorp.Framework.NotificationsDaemon.exe";
        RunDaemonService(notificationsDaemon, "3");

        string pushNotificationsDaemon = "Infocorp.Framework.PushNotificationsDaemon.exe";
        RunDaemonService(pushNotificationsDaemon, null);

        PageInfo.InnerHtml = PageInfo.InnerHtml + "<h3>Running daemons...Done! / <p style='display:inline;font-size: 80%;'>Time: " + DateTime.Now.ToString("dd-MM-yyyy hh:mm:ss") + "</p></h3>";
        
        RunDaemon_Messaging.Enabled = true;
        RunDaemon_Notifications.Enabled = true;
        RunDaemon_PushNotifications.Enabled = true;
    }

    public void Daemon_Notifications_RunIT(Object sender, EventArgs e)
    {
        string daemonName = "Infocorp.Framework.NotificationsDaemon.exe";
        RunDaemonService(daemonName, "3");
        RunDaemon_Notifications.Enabled = true;
    }
    public void Daemon_Messaging_RunIT(Object sender, EventArgs e)
    {
        string daemonName = "Infocorp.Framework.MessagingDaemon.exe";
        RunDaemonService(daemonName, null);
        RunDaemon_Messaging.Enabled = true;
    }
    public void Daemon_PushNotifications_RunIT(Object sender, EventArgs e)
    {
        string daemonName = "Infocorp.Framework.PushNotificationsDaemon.exe";
        RunDaemonService(daemonName, null);
        RunDaemon_PushNotifications.Enabled = true;
    }

    public void Clean(Object sender, EventArgs e)
    {
        var environment = Environment.SelectedValue;
        PageInfo.InnerHtml = "";
    }
</script>

<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="José Luis Yañez Rojas" />
    <meta name="generator" content="RlyehDoom 0.0.1" />

    <title>Republic Bank - Daemons:VQANEW_RBL</title>
    <link href="bootstrap/assets/dist/css/bootstrap.min.css" rel="stylesheet" />

    <script type="text/javascript">
        function CleanThis(sender, args) {
            var e = document.getElementById("Environment");
            var environment = e.options[e.selectedIndex].value;
            document.getElementById("PageInfo").innerHTML = '<h2>Environment: ' + environment + '</h2><h3>Please wait...</h3>';
            console.log('Button [' + sender.id + '] Execute clicked!');
        }
    </script>
    <script type="text/javascript">
        function DisableButton() {
            document.getElementById('RunDaemon_Messaging').disabled = true;
            document.getElementById('RunDaemon_Notifications').disabled = true; 
            document.getElementById('RunDaemon_PushNotifications').disabled = true;
        }
        window.onbeforeunload = DisableButton;
    </script>
    <style>
        body {
            background-image: linear-gradient(180deg, #eee, #fff 100px, #fff);
        }

        .container {
            max-width: 960px;
        }

        .bd-placeholder-img {
            font-size: 1.125rem;
            text-anchor: middle;
            -webkit-user-select: none;
            -moz-user-select: none;
            user-select: none;
        }

        @media (min-width: 768px) {
            .bd-placeholder-img-lg {
                font-size: 3.5rem;
            }
        }
    </style>
</head>
<body>
    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="check" viewBox="0 0 16 16">
            <title>Check</title>
            <path d="M13.854 3.646a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L6.5 10.293l6.646-6.647a.5.5 0 0 1 .708 0z" />
        </symbol>
    </svg>
    <div class="container py-3">
        <form id="formMain" runat="server">
            <header>
                <div class="d-flex flex-column flex-md-row align-items-center pb-3 mb-4 border-bottom">
                    <a href="/" class="d-flex align-items-center text-dark text-decoration-none">
                        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="32" class="me-2" viewBox="0 0 118 94" role="img">
                            <title>Bootstrap</title>
                            <path fill-rule="evenodd" clip-rule="evenodd" d="M24.509 0c-6.733 0-11.715 5.893-11.492 12.284.214 6.14-.064 14.092-2.066 20.577C8.943 39.365 5.547 43.485 0 44.014v5.972c5.547.529 8.943 4.649 10.951 11.153 2.002 6.485 2.28 14.437 2.066 20.577C12.794 88.106 17.776 94 24.51 94H93.5c6.733 0 11.714-5.893 11.491-12.284-.214-6.14.064-14.092 2.066-20.577 2.009-6.504 5.396-10.624 10.943-11.153v-5.972c-5.547-.529-8.934-4.649-10.943-11.153-2.002-6.484-2.28-14.437-2.066-20.577C105.214 5.894 100.233 0 93.5 0H24.508zM80 57.863C80 66.663 73.436 72 62.543 72H44a2 2 0 01-2-2V24a2 2 0 012-2h18.437c9.083 0 15.044 4.92 15.044 12.474 0 5.302-4.01 10.049-9.119 10.88v.277C75.317 46.394 80 51.21 80 57.863zM60.521 28.34H49.948v14.934h8.905c6.884 0 10.68-2.772 10.68-7.727 0-4.643-3.264-7.207-9.012-7.207zM49.948 49.2v16.458H60.91c7.167 0 10.964-2.876 10.964-8.281 0-5.406-3.903-8.178-11.425-8.178H49.948z" fill="currentColor"></path></svg>
                        <span class="fs-4">Daemon's executor</span>
                    </a>

                    <nav class="d-inline-flex mt-2 mt-md-0 ms-md-auto">
                        <asp:LinkButton CssClass="me-3 py-2 text-dark text-decoration-none" runat="server" OnClick="Clean">Clean Results</asp:LinkButton>
                        <asp:LinkButton CssClass="py-2 text-dark text-decoration-none" runat="server" OnClientClick="CleanThis(this);" OnClick="DaemonRunit">Execute All</asp:LinkButton>
                    </nav>
                </div>
                <div class="pricing-header p-3 pb-md-4 mx-auto text-center">
                    <h1 class="display-4 fw-normal">Daemon's Executor</h1>
                    <p class="fs-5 text-muted">Use this web page to execute a specific Daemon from your environments.</p>
                </div>
            </header>
            <main>
                <div class="row g-3">
                    <div class="col-auto">
                        <label for="Environment" class="col-sm-2 col-form-label text-nowrap">Select Environment:</label>
                    </div>
                    <div class="col-auto">
                        <asp:DropDownList ID="Environment" runat="server" CssClass="form-control" ClientIDMode="Static" OnSelectedIndexChanged="Environment_SelectedIndexChanged" AutoPostBack="true" Style="display: inline;">
                            <asp:ListItem Text="RBEC_QA" Value="RBEC_QA" Selected="True"></asp:ListItem>
                            <asp:ListItem Text="RBL_SM_QA" Value="RBL_SM_QA"></asp:ListItem>
                            <asp:ListItem Text="RBL_BVI_QA" Value="RBL_BVI_QA"></asp:ListItem>
                        </asp:DropDownList>
                    </div>
                    <div class="col-auto">
                    </div>
                </div>
                <br />
                <div class="row mb-3">
                    <label for="MessagingDaemonParams" class="col-sm-4 col-form-label text-nowrap">Messaging Daemon :</label>
                    <div class="col-sm-6">
                        <input type="text" id="MessagingDaemonParams" class="form-control" placeholder="No Parameters" />                    
                    </div>
                    <div class="col-sm-2">
                        <asp:Button ID="RunDaemon_Messaging" runat="server" CssClass="btn btn-primary" Text="Run" OnClientClick="CleanThis(this);" OnClick="Daemon_Messaging_RunIT" />
                    </div>
                </div>
                <div class="row mb-3">
                    <label for="NotificationsDaemonParams" class="col-sm-4 col-form-label text-nowrap">Notifications Daemon :</label>
                    <div class="col-sm-6">
                        <input type="text" id="NotificationsDaemonParams" class="form-control" placeholder="No Parameters" value="3" data-bs-toggle="tooltip" data-bs-placement="top" title="This Daemon use the Parameter value '3'" />
                    </div>
                    <div class="col-sm-2">
                        <asp:Button ID="RunDaemon_Notifications" runat="server" CssClass="btn btn-primary" Text="Run" OnClientClick="CleanThis(this);" OnClick="Daemon_Notifications_RunIT" />
                    </div>
                </div>
                <div class="row mb-3">
                    <label for="PushNotificationsDaemonParams" class="col-sm-4 col-form-label text-nowrap">Push Notifications Daemon :</label>
                    <div class="col-sm-6">
                        <input type="text" id="PushNotificationsDaemonParams" class="form-control" placeholder="No Parameters" />
                    </div>
                    <div class="col-sm-2">
                        <asp:Button ID="RunDaemon_PushNotifications" runat="server" CssClass="btn btn-primary" Text="Run" OnClientClick="CleanThis(this);" OnClick="Daemon_PushNotifications_RunIT" />
                    </div>
                </div>
                <h3>Results: 
                  <p id="PageInfo" class="lead" runat="server"></p>
                </h3>
            </main>
        </form>
    </div>

    <script src="bootstrap/assets/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
        var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl)
        });
    </script>
</body>
</html>
