импортировать Swiftui  
Импорт Firebasecore   

@основной    
struct  props_app : app {      
    // rereypriruemem delegat priloжenipear -olegathy -eprilosehenip      
    @UiapplicationDelegateAdaptor  (AppDelegate .self ) VAR Делегат        
    
    ВАР КОЛИЦА: какая -то сцена {        
        Windowgroup {  
            ProjectListView ()        
        } 
    } 
} 

Класс AppDelegate: NSOBject, UIAPPLICATIONDELEGATE  { 
    фонд (_  prileжeniee: uiapplication,        
                    DofinishLaunchingWithoptions LaunchOptions: [uiApplication.launchoptionskey : есть]? = ноль ) -> bool {  
        // инигиали -а -ая  
        Firebaseapp.configure  ()  
        вернуть правду 
    }  
} 
