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
            PageInfo.InnerHtml = PageInfo.InnerHtml + "<h3>Running Daemon [" + daemonName + "]</h3><br />";
            process = System.Diagnostics.Process.Start(processInfo);
            output = process.StandardOutput.ReadToEnd();
            error = process.StandardError.ReadToEnd();
            process.WaitForExit(300000); //5 Minutos
            exitCode = process.ExitCode;
            if (exitCode != 0 || error.Contains("ERR!") || error.Contains("Error") || error.Contains("error"))
            {
                PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing [" + daemonName + " 3] ExitCode:{0} Error:{1}", exitCode, error) + "<br />";
            }
            output = string.IsNullOrEmpty(output) ? "No Response..." : output;
            PageInfo.InnerHtml = PageInfo.InnerHtml + output + "<br/>";
        }
        catch (Exception ex)
        {
            PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing [" + daemonName + " 3] Error:{0}", ex.Message) + "<br />";
        }
    }

    public void DaemonRunit(Object sender, EventArgs e)
    {
        var environment = Environment.SelectedValue;
        PageInfo.InnerHtml = "<h2>Environment: " + environment + "</h2><br />";

        //Infocorp.Framework.NotificationsDaemon.exe
        string notificationsDaemon = "Infocorp.Framework.NotificationsDaemon.exe";
        RunDaemonService(notificationsDaemon, "3");

        //Infocorp.Framework.MessagingDaemon.exe
        string messagingDaemon = "Infocorp.Framework.MessagingDaemon.exe";
        RunDaemonService(messagingDaemon, null);

        //Infocorp.Framework.PushNotificationsDaemon.exe
        string pushNotificationsDaemon = "Infocorp.Framework.PushNotificationsDaemon.exe";
        RunDaemonService(pushNotificationsDaemon, null);

        PageInfo.InnerHtml = PageInfo.InnerHtml + "<h3>Running daemons...Done! / <p style='display:inline;font-size: 80%;'>Time: " + DateTime.Now.ToString("dd-MM-yyyy hh:mm:ss") + "</p></h3>";
        RunDaemon.Enabled = true;
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
    <title>Republic Bank - Daemons:VQANEW_RBL</title>
    <script type="text/javascript">
        function CleanThis(sender, args) {
            var e = document.getElementById("Environment");
            var environment = e.options[e.selectedIndex].value;
            document.getElementById("PageInfo").innerHTML = '<h2>Environment: ' + environment + '</h2><h3>Please wait...</h3>';
            //document.getElementById("RunDaemon").disabled = true;
            console.log('Button Execute clicked!');
            /*
            var theForm = document.forms['form1'];
            if (!theForm) {
                theForm = document.form1;
            }
            theForm.submit();*/
        }
    </script>
    <script type="text/javascript">
        function DisableButton() {
            document.getElementById('RunDaemon').disabled = true;
        }
        window.onbeforeunload = DisableButton;
    </script>
    <style>
        br {
            display: block;
            margin-top: 10px;
            line-height: 22px;
        }

        h1 {
            margin-top: 10px;
            margin-bottom: 10px;
        }

        h2 {
            margin-top: 10px;
            margin-bottom: 10px;
        }

        h3 {
            margin-top: 8px;
            margin-bottom: 8px;
        }

        h4 {
            margin-top: 5px;
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <table style="width: 50%">
            <tr>
                <td style="text-align: left;">
                    <table>
                        <tr>
                            <td>
                                <p><b>Seleccione Build:</b> </p>
                            </td>
                            <td>
                                <asp:DropDownList ID="Environment" runat="server" ClientIDMode="Static" OnSelectedIndexChanged="Environment_SelectedIndexChanged" AutoPostBack="true" Style="display: inline;">
                                    <asp:ListItem Text="RBEC_QA" Value="RBEC_QA" Selected="True"></asp:ListItem>
                                    <asp:ListItem Text="RBL_SM_QA" Value="RBL_SM_QA"></asp:ListItem>
                                    <asp:ListItem Text="RBL_BVI_QA" Value="RBL_BVI_QA"></asp:ListItem>
                                </asp:DropDownList>
                            </td>
                        </tr>
                    </table>
                </td>
                <td style="text-align: left;">
                    <asp:Button ID="RunDaemon" ClientIDMode="Static" runat="server" OnClientClick="CleanThis();" UseSubmitBehavior="false" OnClick="DaemonRunit" Text="Execute Daemon's" />
                </td>
                <td>
                    <asp:Button ID="CleanScreen" ClientIDMode="Static" runat="server" OnClick="Clean" Text="Clean..." />
                </td>
            </tr>
        </table>
        <br />
        <table style="width: 100%">
            <tr>
                <td style="text-align: left;">
                    <div id="PageInfo" runat="server"></div>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
