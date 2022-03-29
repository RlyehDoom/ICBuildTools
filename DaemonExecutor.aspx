<%@ Page Language="C#" EnableViewState="true" AutoEventWireup="true" %>

<%@ Import Namespace="System.ComponentModel" %>
<%@ Import Namespace="System.Threading.Tasks" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Web.Services" %>
<%@ Import Namespace="System.Web.Script.Services" %>
<!-- 
    This page need to run with an specific 'APP Pool' running with Admin credentials or the same user who installed NPM/NODE amd GULP-CLI.
 -->
<script language="c#" runat="server">

    Microsoft.Web.Administration.ServerManager serverManager = new Microsoft.Web.Administration.ServerManager();
    System.Diagnostics.ProcessStartInfo processInfo;
    System.Diagnostics.Process process;

    #region CONFIGURATIONS
    //Allowed Users.
    public static string[] AllowedUsers = { "*" };
    //List of your active Deployment Environments:
    public static List<string> Environments = new List<string>() { "RBEC_QA", "RBL_SM_QA", "RBL_BVI_QA" };
    //List of Daemons (Add your Daemon here and that's it!):
    public static List<KeyValuePair<string, string>> DaemonsExecutableList = new List<KeyValuePair<string, string>>() {
                new KeyValuePair<string, string>("Infocorp.Framework.NotificationsDaemon.exe", "3"),
                new KeyValuePair<string, string>("Infocorp.Framework.MessagingDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.Framework.PushNotificationsDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.Framework.TaskProcessingDaemon.exe", "1"),
                new KeyValuePair<string, string>("Infocorp.Framework.TaskProcessingDaemon.exe-4", "4"),
                new KeyValuePair<string, string>("Infocorp.Framework.BackOfficeMessageDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.Framework.UserGroupsDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.PersonalFinance.RegisteredUsersProcessingDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.P2P.CollectsExpeditionDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.P2P.PaymentExpeditionDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.P2P.PaymentExpirationReminderDaemon.exe", ""),
                new KeyValuePair<string, string>("Infocorp.P2P.PaymentProcessingDaemon.exe", ""),
                //Republic Bank Daemons
                new KeyValuePair<string, string>("Tailored.Framework.CreditCardDataFillDaemon.exe", ""),
                new KeyValuePair<string, string>("Tailored.Framework.CreditCardNotificationsDaemon.exe", ""),
                new KeyValuePair<string, string>("Tailored.Framework.DailyFilesDaemon.exe", "")
    };
    #endregion

    public string outputHTMLResponse;

    public void Page_Load(object sender, EventArgs e)
    {
        Page.Server.ScriptTimeout = 7200;
        var environment = Environment.SelectedValue;

        if (!Page.IsPostBack)
        {
            string allowedUsersString = ConfigurationManager.AppSettings["AllowedUsersDaemon"].ToString();
            if (!string.IsNullOrEmpty(allowedUsersString) && allowedUsersString != "*")
            {
                string userName = System.Security.Principal.WindowsIdentity.GetCurrent().Name.ToString().Split('\\')[1].ToLower();
                AllowedUsers = allowedUsersString.ToLower().Split(',');
                if (AllowedUsers.Where(p => p.Contains(userName)).Count() > 0)
                {
                    allowedContent.Visible = true;
                    notAllowedContent.Visible = false;
                }
                else
                {
                    allowedContent.Visible = false;
                    notAllowedContent.Visible = true;
                }
            }
            else
            {
                allowedContent.Visible = true;
                notAllowedContent.Visible = false;
            }
        }
    }
    protected void Page_Init(object sender, EventArgs e)
    {
        DaemonsRepeater.DataSource = DaemonsExecutableList;
        DaemonsRepeater.DataBind();

        Environment.DataSource = Environments;
        Environment.DataBind();
    }
    public void Environment_SelectedIndexChanged(Object sender, EventArgs e)
    {
        var environment = Environment.SelectedValue;
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
            string baseBuildDirectoryPath = ConfigurationManager.AppSettings["BaseBuildDirectoryPath"].ToString();
            string daemonNameDirectory = ConfigurationManager.AppSettings["DaemonNameDirectoryPath"].ToString();
            string fullDaemonPath = System.IO.Path.Combine(baseBuildDirectoryPath + environment + daemonNameDirectory, daemonName);
            param = string.IsNullOrEmpty(parameters) ? "" : string.Concat("| ", parameters);

            if (!string.IsNullOrEmpty(parameters))
                processInfo = new System.Diagnostics.ProcessStartInfo(fullDaemonPath, parameters);
            else
                processInfo = new System.Diagnostics.ProcessStartInfo(fullDaemonPath);

            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            processInfo.RedirectStandardError = true;
            processInfo.RedirectStandardOutput = true;
            
            process = System.Diagnostics.Process.Start(processInfo);
            output = process.StandardOutput.ReadToEnd();
            error = process.StandardError.ReadToEnd();
            process.WaitForExit(300000 * 3); //15 Minutos
            exitCode = process.ExitCode;

            if (exitCode != 0 || error.Contains("ERR!") || error.Contains("Error") || error.Contains("error"))
            {
                PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing...<br />Parameters:{0}<br />ExitCode:{1} Error Message:{2}<br />", param, exitCode, error) + "<br />";
            }
            string result = Regex.Replace(output, @"\r\n?|\n", "<br />");
            result = string.IsNullOrEmpty(result) ? "No Response..." : result;
            PageInfo.InnerHtml = "<h4>Daemon =></h4><h5>[" + daemonName + "]:</h5>" + result + PageInfo.InnerHtml;
        }
        catch (Exception ex)
        {
            PageInfo.InnerHtml = PageInfo.InnerHtml + string.Format("Error executing...<br />Parameters:{0}<br />Error Message:{1}<br />", param, ex.Message) + "<br />";
        }
    }

    public void DaemonRunit(Object sender, EventArgs e)
    {
        foreach (KeyValuePair<string, string> value in DaemonsExecutableList)
        {
            string daemonName = value.Key.Split('-')[0];
            string daemonParameters = value.Value;
            RunDaemonService(daemonName, daemonParameters);
        }

        PageInfo.InnerHtml = PageInfo.InnerHtml + "<br /><h3>Running daemons...Done! / <p style='display:inline;font-size: 80%;'>Time: " + DateTime.Now.ToString("dd-MM-yyyy hh:mm:ss") + "</p></h3>";
    }

    public void Daemon_RunIT(Object sender, EventArgs e)
    {
        Button button = (Button)sender;
        string daemonParameter = button.CommandArgument;
        string daemonName = button.CommandName.Replace("_", ".").Replace("-" + daemonParameter, "");

        Debug.WriteLine("DaemonName: " + daemonName + " | DaemonParameter: " + daemonParameter);

        RunDaemonService(daemonName, daemonParameter);
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
    <meta name="description" content=".NET's Executor" />
    <meta name="author" content="José Luis Yañez Rojas" />
    <meta name="generator" content="RlyehDoom 0.0.1" />

    <title>.NET's Executor</title>
    <link href="bootstrap/assets/dist/css/bootstrap.min.css" rel="stylesheet" />

    <script type="text/javascript">
        function CleanThis(sender, args) {
            document.getElementById("PageInfo").innerHTML = '<h2 class="text-danger">Running a Daemon!.</h2><br/><h4>Please patiently wait for a response here...</h4>';
            console.log('Button [' + sender.id + '] Execute clicked!');
        }
        function RunAllDaemons(sender, args) {
            document.getElementById("PageInfo").innerHTML = '<h2 class="text-danger">Running All Daemons!.</h2><br/><h4>Please patiently wait for a response here...</h4>';
            console.log('Button [' + sender.id + '] Execute clicked!');
        }
    </script>
    <script type="text/javascript">
        function DisableButton() {
            $(':input[type="submit"]').prop('disabled', true);
            $('a').on("click", function (e) {
                e.preventDefault();
            });
        }
        window.onbeforeunload = DisableButton;
    </script>
    <style>
        body {
            background-image: linear-gradient(180deg, #eee, #fff 100px, #fff);
        }

        .container {
            max-width: 1280px;
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
    <script src="jquery/jquery-3.6.0.min.js"></script>
    <script type="text/javascript">
        $(document).ready(function () {

        });
    </script>
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
                        <span class="fs-4">.NET's Executor</span>
                    </a>

                    <nav class="d-inline-flex mt-2 mt-md-0 ms-md-auto">
                        <asp:LinkButton ID="CleanButton" ClientIDMode="Static" CssClass="me-3 py-2 text-dark text-decoration-none" runat="server" OnClick="Clean">Clean Results</asp:LinkButton>
                        <asp:LinkButton ID="RunAllButton" ClientIDMode="Static" CssClass="py-2 text-dark text-decoration-none" runat="server" OnClientClick="RunAllDaemons(this);" OnClick="DaemonRunit">Execute All</asp:LinkButton>
                    </nav>
                </div>
                <div class="pricing-header p-3 pb-md-4 mx-auto text-center">
                    <h1 class="display-4 fw-normal">.NET's Executor</h1>
                    <p class="fs-5 text-muted">Use this web page to execute a specific Daemon from your environment.</p>
                </div>
            </header>
            <main>
                <div id="allowedContent" runat="server" class="row">
                    <div class="row g-3">
                        <div class="col-auto">
                            <label for="Environment" class="col-sm-2 col-form-label text-nowrap">Select Environment:</label>
                        </div>
                        <div class="col-auto">
                            <asp:DropDownList ID="Environment" runat="server" CssClass="form-control" ClientIDMode="Static" OnSelectedIndexChanged="Environment_SelectedIndexChanged" AutoPostBack="true" Style="display: inline;">
                            </asp:DropDownList>
                        </div>
                        <div class="col-auto">
                        </div>
                    </div>
                    <br />
                    <div class="col">
                        <asp:Repeater ID="DaemonsRepeater" runat="server">
                            <ItemTemplate>
                                <div class="row mb-3">
                                    <label for="Input_<%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Key").ToString().Replace(".","_") %>" class="col-sm-6 col-form-label text-nowrap"><%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Key").ToString().Split('.')[2] %> :</label>
                                    <div class="col-sm-4">
                                        <input type="text" id="Input_<%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Key").ToString().Replace(".","_") %>" class="form-control" placeholder="No Parameters" value="<%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Value").ToString() %>" />
                                    </div>
                                    <div class="col-sm-2">
                                        <asp:Button ID="DaemonRunButton" runat="server" CommandArgument='<%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Value") %>' CommandName='<%# DataBinder.Eval((KeyValuePair<string, string>)Container.DataItem, "Key").ToString().Replace(".","_") %>' Text="Run" CssClass="btn btn-primary" OnClientClick="CleanThis(this);" OnClick="Daemon_RunIT" />
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                    <div class="col">
                        <h3>Results: 
                            <p id="PageInfo" class="lead" runat="server"></p>
                        </h3>
                    </div>
                </div>
                <div id="notAllowedContent" runat="server" class="row">
                    <div class="col">
                        <h3>Warning: 
                            <p class="lead text-danger">You don't have permissions to operate this page...</p>
                        </h3>
                    </div>
                </div>
            </main>
            <asp:ScriptManager ID="MyScriptManager" runat="server">
            </asp:ScriptManager>
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
