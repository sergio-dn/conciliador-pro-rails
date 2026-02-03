import { application } from "./application"
import FileUploadController from "./file_upload_controller"
import DragDropController from "./drag_drop_controller"
import TabsController from "./tabs_controller"

application.register("file-upload", FileUploadController)
application.register("drag-drop", DragDropController)
application.register("tabs", TabsController)
