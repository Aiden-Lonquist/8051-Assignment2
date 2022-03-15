//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update();
        
    }
}

class ViewController: GLKViewController {
    
    @IBOutlet weak var myLabel: UILabel!
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2;
        view.addGestureRecognizer(doubleTap)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect);
    }
    
    @objc func doDoubleTap(_ sender: UITapGestureRecognizer) {
        glesRenderer.isRotating = !glesRenderer.isRotating;
    }
    
    @IBAction func toggleFog(_ sender: Any) {
        glesRenderer.useFog = !glesRenderer.useFog;
    }
}
